#!/usr/bin/env python3
"""
MongoDB Integration Demo for Service Monitor

This script demonstrates the complete MongoDB logging integration:
1. Service status logging
2. Event logging
3. Query capabilities
4. Real-time monitoring data
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
    try:
        from database import log_operations, LogEntry, EventEntry, LogLevel, ServiceStatus
        from datetime import datetime, timedelta

        print("🎯 MongoDB Integration Demo - Service Monitor")
        print("=" * 50)

        # Check connection
        if not log_operations.connection.connect():
            print("❌ Could not connect to MongoDB")
            return 1

        print("✅ Connected to MongoDB")

        # 1. Show recent service monitoring logs
        print("\n📊 Recent Service Monitor Logs (last 24h)")
        print("-" * 40)

        services = ['dbus.service', 'service_monitor']
        for service in services:
            logs = log_operations.get_recent_logs(service, hours=24, limit=5)
            if logs:
                print(f"\n🔍 {service} ({len(logs)} recent logs):")
                for i, log in enumerate(logs[:3], 1):
                    timestamp = log.get('timestamp', 'N/A')
                    level = log.get('log_level', 'INFO')
                    message = log.get('message', '')[:60]
                    host = log.get('host', 'unknown')
                    service_type = log.get('service_type', 'local')

                    print(f"  {i:2d}. [{level}] {timestamp}")
                    print(f"      Host: {host} ({service_type})")
                    print(f"      Message: {message}")

                    metadata = log.get('metadata', {})
                    if metadata:
                        print(f"      Metadata: {metadata}")
                    print()

        # 2. Show monitoring events
        print("\n🎪 Recent Monitor Events")
        print("-" * 30)

        events_collection = log_operations.connection.events_collection
        if events_collection is not None:
            events = list(events_collection.find().sort('timestamp', -1).limit(5))

            if events:
                for i, event in enumerate(events, 1):
                    event_type = event.get('event_type', 'unknown')
                    service = event.get('service_name', 'unknown')
                    description = event.get('description', '')
                    timestamp = event.get('timestamp', 'N/A')
                    severity = event.get('severity', 'INFO')

                    print(f"  {i:2d}. [{severity}] {timestamp}")
                    print(f"      Event: {event_type} ({service})")
                    print(f"      Description: {description}")

                    metadata = event.get('metadata', {})
                    if metadata:
                        relevant_meta = {k: v for k, v in metadata.items()
                                       if k in ['target_count', 'action', 'success', 'return_code']}
                        if relevant_meta:
                            print(f"      Details: {relevant_meta}")
                    print()
            else:
                print("   No events found")

        # 3. Show service statistics
        print("\n📈 Service Statistics (last 24h)")
        print("-" * 35)

        for service in ['dbus.service']:
            stats = log_operations.get_service_statistics(service, hours=24)
            if stats and stats.get('total_logs', 0) > 0:
                print(f"\n📊 {service}:")
                print(f"   Total logs: {stats['total_logs']}")
                print(f"   By level: {stats['by_level']}")
                print(f"   Latest activity: {stats['latest_activity']}")

        # 4. Demonstrate the data structure
        print("\n🏗️  MongoDB Data Structure")
        print("-" * 30)

        recent_log = log_operations.get_logs(limit=1)
        if recent_log:
            log = recent_log[0]
            print("📝 Example Service Log Document:")
            for key, value in log.items():
                if key != '_id':
                    print(f"   {key}: {value}")

        print("\n✅ Demo completed!")
        print(f"💾 Database: {log_operations.connection.config.database_name}")
        print(f"📊 Collections: logs, events")
        print(f"🔍 Query tools: check_mongodb_logs.py")

        return 0

    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Make sure MongoDB dependencies are installed")
        return 1
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())