#!/usr/bin/env python3
"""
API Demo Script

Test the MongoDB operations and show API functionality without running the server
"""

import os
import sys

# Setup Python path
project_root = os.path.dirname(os.path.abspath(__file__))
venv_path = os.path.join(project_root, "venv")
venv_site_packages = os.path.join(venv_path, "lib", f"python{sys.version_info.major}.{sys.version_info.minor}", "site-packages")

if os.path.exists(venv_site_packages):
    sys.path.insert(0, venv_site_packages)
sys.path.insert(0, project_root)

def main():
    try:
        from database import log_operations
        from datetime import datetime

        print("🎯 API Demo - Simulación de endpoints")
        print("=" * 50)

        # Test 1: Health Check
        print("\n🔍 1. Health Check")
        connection_healthy = log_operations.connection.health_check()
        print(f"   Status: {'healthy' if connection_healthy else 'unhealthy'}")
        print(f"   Database: {log_operations.connection.config.database_name}")

        if not connection_healthy:
            print("   ⚠️  MongoDB no disponible - simulando datos")
            return

        # Test 2: Get service summary (API endpoint: GET /services)
        print("\n🔧 2. Services Summary (GET /services)")
        summary = log_operations.get_service_summary()
        print(f"   Total services: {summary.get('total_services', 0)}")

        for service in summary.get('services', [])[:3]:
            service_name = service.get('_id', 'unknown')
            total_logs = service.get('total_logs', 0)
            unsent_logs = service.get('unsent_logs', 0)
            print(f"   📊 {service_name}: {total_logs} total, {unsent_logs} unsent")

        # Test 3: Get unsent logs (API endpoint: GET /logs/unsent)
        print("\n📮 3. Unsent Logs (GET /logs/unsent)")
        unsent_logs = log_operations.get_unsent_logs(limit=5)
        print(f"   Found: {len(unsent_logs)} unsent logs")

        for i, log in enumerate(unsent_logs[:3], 1):
            service = log.get('service_name', 'unknown')
            timestamp = log.get('timestamp', 'N/A')
            level = log.get('log_level', 'INFO')
            print(f"   {i}. [{level}] {service} - {timestamp}")

        # Test 4: Mark logs as sent (API endpoint: POST /logs/mark-sent)
        if unsent_logs:
            print("\n✅ 4. Mark Logs as Sent (POST /logs/mark-sent)")

            # Get IDs from first 2 logs
            log_ids = []
            for log in unsent_logs[:2]:
                if '_id' in log:
                    log_ids.append(str(log['_id']))

            if log_ids:
                marked_count = log_operations.mark_logs_as_sent(log_ids)
                print(f"   Marked {marked_count} logs as sent")
                print(f"   Log IDs: {log_ids[:2]}")

                # Verify - check unsent logs again
                new_unsent = log_operations.get_unsent_logs(limit=5)
                print(f"   Remaining unsent: {len(new_unsent)} logs")

        # Test 5: Service statistics (API endpoint: GET /stats/service_name)
        print("\n📈 5. Service Statistics (GET /stats/{service_name})")
        if summary.get('services'):
            service_name = summary['services'][0].get('_id', 'dbus.service')
            stats = log_operations.get_service_statistics(service_name, hours=24)

            if stats:
                print(f"   Service: {service_name}")
                print(f"   Total logs (24h): {stats.get('total_logs', 0)}")
                print(f"   By level: {stats.get('by_level', {})}")
                print(f"   Latest activity: {stats.get('latest_activity', 'N/A')}")

        # Test 6: General logs query (API endpoint: GET /logs)
        print("\n📝 6. Recent Logs (GET /logs?limit=3)")
        recent_logs = log_operations.get_logs(limit=3)
        print(f"   Found: {len(recent_logs)} recent logs")

        for i, log in enumerate(recent_logs, 1):
            service = log.get('service_name', 'unknown')
            level = log.get('log_level', 'INFO')
            message = log.get('message', '')[:50]
            sent = log.get('sent_to_user', False)
            print(f"   {i}. [{level}] {service} - {message}... (sent: {sent})")

        print(f"\n✅ API Demo completado")
        print(f"🌐 Para ejecutar API real: ./run_api.sh")
        print(f"📚 Endpoints disponibles:")
        print(f"   GET  /health - Health check")
        print(f"   GET  /stats - Estadísticas generales")
        print(f"   GET  /services - Resumen de servicios")
        print(f"   GET  /logs - Obtener logs")
        print(f"   GET  /logs/unsent - Logs no enviados")
        print(f"   POST /logs/mark-sent - Marcar logs como enviados")

    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Asegúrese de que las dependencias de MongoDB estén instaladas")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()