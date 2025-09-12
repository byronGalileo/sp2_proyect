#!/usr/bin/env python3
"""
service-monitor: Monitor configurable de servicios systemd (local/SSH), con:
- intervalos por servicio (interval_sec en cada target)
- bandera booleana 'active' en los logs
- posibilidad de habilitar/deshabilitar targets desde config (active: true/false)
- intento de remediación (start/restart) sin sudo primero, con opción 'use_sudo' por target
"""
import argparse
import json
import logging
from logging.handlers import RotatingFileHandler
import subprocess
import time
import shlex
import os

DEFAULT_LOG = "logs/service_monitor.log"

def shell(cmd: str, timeout: int = 20) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)

def systemctl_is_active_local(service: str) -> str:
    cp = shell(f"systemctl is-active {shlex.quote(service)}")
    # returncode: 0=active, 3=inactive/failed, otros=errores
    return cp.stdout.strip() if cp.returncode in (0,3) else (cp.stdout.strip() or cp.stderr.strip())

def systemctl_action_local(service: str, action: str, use_sudo: bool=False, user: str=None, password: str=None) -> subprocess.CompletedProcess:
    action = "restart" if action == "restart" else "start"
    
    if user and password:
        # Use su to switch to the specified user
        cmd = f"echo {shlex.quote(password)} | su -c 'systemctl {action} {shlex.quote(service)}' {shlex.quote(user)}"
    else:
        base = "sudo systemctl" if use_sudo else "systemctl"
        cmd = f"{base} {action} {shlex.quote(service)}"
    
    return shell(cmd)

def systemctl_is_active_ssh(user: str, host: str, port: int, service: str) -> str:
    cmd = f"ssh -p {port} -o BatchMode=yes -o StrictHostKeyChecking=accept-new {shlex.quote(user)}@{shlex.quote(host)} systemctl is-active {shlex.quote(service)}"
    cp = shell(cmd)
    return cp.stdout.strip() if cp.returncode in (0,3) else (cp.stdout.strip() or cp.stderr.strip())

def systemctl_action_ssh(user: str, host: str, port: int, service: str, action: str, use_sudo: bool=False) -> subprocess.CompletedProcess:
    action = "restart" if action == "restart" else "start"
    base = "sudo systemctl" if use_sudo else "systemctl"
    cmd = f"ssh -p {port} -o BatchMode=yes -o StrictHostKeyChecking=accept-new {shlex.quote(user)}@{shlex.quote(host)} {base} {shlex.quote(action)} {shlex.quote(service)}"
    return shell(cmd)

def setup_logger(log_path: str, level: str = "INFO") -> logging.Logger:
    logger = logging.getLogger("service_monitor")
    if logger.handlers:
        return logger  # evita handlers duplicados
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    handler = RotatingFileHandler(log_path, maxBytes=2*1024*1024, backupCount=5)
    fmt = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
    handler.setFormatter(fmt)
    logger.addHandler(handler)
    console = logging.StreamHandler()
    console.setFormatter(fmt)
    logger.addHandler(console)
    return logger

def monitor_target(logger: logging.Logger, target: dict) -> None:
    enabled = target.get("active", True)
    name = target.get("name") or f"{target.get('host','local')}:{target.get('service','?')}"
    if not enabled:
        logger.info(f"[{name}] skip=target_disabled")
        return

    method = target.get("method","local")
    service = target["service"]
    recover = target.get("recover_on_down", True)
    recover_action = target.get("recover_action","start")  # start|restart
    timeout = int(target.get("timeout_sec", 20))
    use_sudo = bool(target.get("use_sudo", False))  # por si quieres forzar sudo explícitamente

    # STATUS
    try:
        if method == "local":
            status = systemctl_is_active_local(service)
        elif method == "ssh":
            ssh = target.get("ssh", {})
            status = systemctl_is_active_ssh(
                user=ssh.get("user",""),
                host=target["host"],
                port=int(ssh.get("port",22)),
                service=service,
            )
        else:
            logger.error(f"[{name}] método desconocido: {method}")
            return
        is_active = (status.strip() == "active")
        logger.info(f"[{name}] status={status} active={is_active}")
    except Exception as e:
        logger.error(f"[{name}] error al consultar estado: {e}")
        return

    # REMEDIACIÓN
    if not is_active:
        if not recover:
            logger.warning(f"[{name}] servicio no activo y recuperación deshabilitada")
            return
        logger.warning(f"[{name}] servicio '{service}' no está activo (status={status}). Intentando {recover_action}...")
        try:
            if method == "local":
                # Get credentials if available
                credentials = target.get("credentials", {})
                user = credentials.get("user")
                password = credentials.get("password")
                
                # First try with credentials if available, otherwise use sudo/no-sudo approach
                if user and password:
                    cp = systemctl_action_local(service, recover_action, use_sudo=False, user=user, password=password)
                else:
                    # Primero intenta sin sudo (Polkit). Si falla por permisos y use_sudo=True, reintenta con sudo.
                    cp = systemctl_action_local(service, recover_action, use_sudo=False)
                    if cp.returncode != 0 and "permission" in (cp.stderr.lower() + cp.stdout.lower()) and use_sudo:
                        cp = systemctl_action_local(service, recover_action, use_sudo=True)
            else:
                ssh = target.get("ssh", {})
                cp = systemctl_action_ssh(
                    user=ssh.get("user",""),
                    host=target["host"],
                    port=int(ssh.get("port",22)),
                    service=service,
                    action=recover_action,
                    use_sudo=use_sudo,
                )
            if cp.returncode == 0:
                logger.info(f"[{name}] {recover_action} ejecutado correctamente")
            else:
                logger.error(f"[{name}] fallo en {recover_action} rc={cp.returncode} out={cp.stdout.strip()} err={cp.stderr.strip()}")
        except Exception as e:
            logger.error(f"[{name}] excepción al intentar {recover_action}: {e}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True, help="Ruta a config.json")
    ap.add_argument("--once", action="store_true", help="Ejecuta una sola vez y sale")
    args = ap.parse_args()

    with open(args.config, "r") as f:
        cfg = json.load(f)

    log_path = cfg.get("log_file", DEFAULT_LOG)
    logger = setup_logger(log_path, cfg.get("log_level","INFO"))

    targets = cfg.get("targets", [])
    if not targets:
        logger.error("No hay 'targets' definidos en el archivo de configuración")
        return

    # Programación por target (cada uno con su interval_sec)
    schedule = {}
    now = time.time()
    for t in targets:
        schedule[id(t)] = now  # ejecutar inmediatamente

    logger.info("Iniciando monitor con %s targets", len(targets))

    def run_cycle():
        now = time.time()
        for t in targets:
            interval = int(t.get("interval_sec", 60))
            key = id(t)
            next_at = schedule.get(key, now)
            if now >= next_at:
                monitor_target(logger, t)
                schedule[key] = now + interval

    if args.once:
        for t in targets:
            monitor_target(logger, t)
        return

    try:
        while True:
            run_cycle()
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Terminando por Ctrl+C")

if __name__ == "__main__":
    main()