
#!/usr/bin/env python3
import argparse, asyncio, json, csv, socket, ssl, time
from datetime import datetime

def parse_ports(ports_str):
    ports = set()
    for part in ports_str.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            ports.update(range(int(a), int(b) + 1))
        else:
            ports.add(int(part))
    return sorted(ports)

async def check_tcp(host, port, timeout):
    loop = asyncio.get_running_loop()
    start = time.perf_counter()
    try:
        conn = asyncio.open_connection(host, port)
        reader, writer = await asyncio.wait_for(conn, timeout=timeout)
        rtt = (time.perf_counter() - start) * 1000.0
        writer.close()
        try:
            await writer.wait_closed()
        except Exception:
            pass
        return {"ok": True, "latency_ms": round(rtt, 2), "error": ""}
    except Exception as e:
        return {"ok": False, "latency_ms": None, "error": str(e)}

async def check_http(host, port, path, timeout, tls=False):
    try:
        reader, writer = await asyncio.wait_for(asyncio.open_connection(host, port, ssl=ssl.create_default_context() if tls else None), timeout=timeout)
        req = f"GET {path} HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\nUser-Agent: port-health-check/1.0\r\n\r\n"
        writer.write(req.encode("utf-8"))
        await writer.drain()
        start = time.perf_counter()
        status_line = await asyncio.wait_for(reader.readline(), timeout=timeout)
        elapsed = (time.perf_counter() - start) * 1000.0
        writer.close()
        try:
            await writer.wait_closed()
        except Exception:
            pass
        try:
            parts = status_line.decode(errors="ignore").split()
            code = int(parts[1]) if len(parts) >= 2 and parts[1].isdigit() else None
        except Exception:
            code = None
        return {"http_status": code, "http_latency_ms": round(elapsed, 2)}
    except Exception:
        return {"http_status": None, "http_latency_ms": None}

async def run_once(args):
    now = datetime.utcnow().isoformat() + "Z"
    tasks = []
    for p in args.ports:
        tasks.append(check_tcp(args.host, p, args.timeout))
    results = await asyncio.gather(*tasks)
    rows = []
    for port, res in zip(args.ports, results):
        row = {
            "timestamp": now,
            "host": args.host,
            "port": port,
            "tcp_ok": res["ok"],
            "tcp_latency_ms": res["latency_ms"],
            "error": res["error"],
            "http_status": None,
            "http_latency_ms": None,
        }
        if args.http and port in (80, 443):
            http_res = await check_http(args.host, port, args.http_path, args.timeout, tls=(port==443))
            row.update(http_res)
        rows.append(row)
    output(rows, args)
    return rows

def output(rows, args):
    print(f"\n=== Port Health @ {rows[0]['timestamp']} ===")
    for r in rows:
        status = "OPEN" if r["tcp_ok"] else "CLOSED"
        extra = ""
        if r["http_status"] is not None:
            extra = f" | HTTP {r['http_status']} in {r['http_latency_ms']} ms"
        lat = f"{r['tcp_latency_ms']} ms" if r['tcp_latency_ms'] is not None else "-"
        print(f"{r['host']}:{r['port']} -> {status} | TCP {lat}{extra}")
        if r["error"] and not r["tcp_ok"]:
            print(f"  error: {r['error']}")

    if args.json_out:
        with open(args.json_out, "a", encoding="utf-8") as f:
            for r in rows:
                f.write(json.dumps(r) + "\n")

    if args.csv_out:
        file_exists = Path(args.csv_out).exists()
        import csv
        with open(args.csv_out, "a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
            if not file_exists:
                writer.writeheader()
            for r in rows:
                writer.writerow(r)

async def main():
    parser = argparse.ArgumentParser(description="Simple local port and HTTP health checker")
    parser.add_argument("--host", default="127.0.0.1", help="Host to check")
    parser.add_argument("--ports", default="22,80,443", help="Comma list and/or ranges, e.g. 22,80,443,8000-8010")
    parser.add_argument("--timeout", type=float, default=1.5, help="TCP/HTTP timeout seconds")
    parser.add_argument("--http", action="store_true", help="Attempt HTTP GET on 80/443")
    parser.add_argument("--http-path", default="/", help="HTTP path to GET for 80/443")
    parser.add_argument("--json-out", help="Append JSON lines output to file")
    parser.add_argument("--csv-out", help="Append CSV output to file")
    parser.add_argument("--watch", type=int, default=0, help="Repeat every N seconds. 0 = run once")
    args = parser.parse_args()

    args.ports = parse_ports(args.ports)

    if args.watch <= 0:
        await run_once(args)
    else:
        try:
            while True:
                await run_once(args)
                await asyncio.sleep(args.watch)
        except KeyboardInterrupt:
            pass

if __name__ == "__main__":
    asyncio.run(main())
