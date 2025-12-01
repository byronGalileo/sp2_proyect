#!/usr/bin/env python3
"""
Quick MongoDB logs checker
Usage: python3 check_mongodb_logs.py [service_name]
"""

import sys
import os

# Setup Python path for imports
project_root = os.path.dirname(os.path.abspath(__file__))
venv_path = os.path.join(project_root, "venv")
venv_site_packages = os.path.join(venv_path, "lib", f"python{sys.version_info.major}.{sys.version_info.minor}", "site-packages")

if os.path.exists(venv_site_packages):
    sys.path.insert(0, venv_site_packages)
sys.path.insert(0, project_root)

def main():
    service_name = sys.argv[1] if len(sys.argv) > 1 else None

    try:
        from database import log_operations

        if service_name:
            print(f"📊 Recent logs for service: {service_name}")
            logs = log_operations.get_recent_logs(service_name, hours=24, limit=10)

            if logs:
                for i, log in enumerate(logs, 1):
                    timestamp = log.get('timestamp', 'N/A')
                    level = log.get('log_level', 'INFO')
                    message = log.get('message', '')[:80]
                    print(f"{i:2d}. [{level}] {timestamp} - {message}")
            else:
                print(f"   No logs found for service: {service_name}")
        else:
            print("📊 Overall MongoDB Log Statistics")

            # Get recent logs from all services
            all_logs = log_operations.get_logs(limit=20)
            print(f"Total recent logs: {len(all_logs)}")

            # Group by service
            services = {}
            for log in all_logs:
                service = log.get('service_name', 'unknown')
                if service not in services:
                    services[service] = {'count': 0, 'latest': None}
                services[service]['count'] += 1
                if services[service]['latest'] is None:
                    services[service]['latest'] = log.get('timestamp')

            print("\nServices in MongoDB:")
            for service, data in services.items():
                print(f"  • {service}: {data['count']} logs (latest: {data['latest']})")

            # Get error logs
            error_logs = log_operations.get_error_logs(hours=24)
            if error_logs:
                print(f"\n⚠️  Recent errors/warnings: {len(error_logs)}")
                for log in error_logs[:5]:
                    service = log.get('service_name', 'unknown')
                    level = log.get('log_level', 'ERROR')
                    message = log.get('message', '')[:60]
                    print(f"   [{level}] {service}: {message}")

        # Connection info
        conn_info = log_operations.connection.get_connection_info()
        print(f"\n🔗 MongoDB: {'✓ Connected' if conn_info['healthy'] else '✗ Disconnected'}")

    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Make sure MongoDB dependencies are installed in venv/")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ['--help', '-h']:
        print("Usage: python3 check_mongodb_logs.py [service_name]")
        print("Examples:")
        print("  python3 check_mongodb_logs.py                    # Show all stats")
        print("  python3 check_mongodb_logs.py dbus              # Show dbus logs")
        print("  python3 check_mongodb_logs.py service_monitor   # Show monitor logs")
        sys.exit(0)

    main()