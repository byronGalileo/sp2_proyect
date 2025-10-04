#!/usr/bin/env python3
"""
Example usage of the MongoDB logging system

This file demonstrates how to use the MongoDB logging structure
for service monitoring.
"""

import os
import sys
from datetime import datetime

# Add the parent directory to Python path to import database module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import log_operations, LogEntry, EventEntry, LogLevel, ServiceStatus

def demo_basic_logging():
    """Demonstrate basic logging operations"""
    print("=== Basic Logging Demo ===")

    # Create sample log entries
    logs = [
        LogEntry(
            service_name="prometheus",
            log_level=LogLevel.INFO,
            message="Service started successfully",
            service_type="local",
            host="monitoring-server",
            status=ServiceStatus.ACTIVE,
            metadata={"port": 9090, "config_file": "/etc/prometheus/prometheus.yml"}
        ),
        LogEntry(
            service_name="mysql",
            log_level=LogLevel.WARNING,
            message="High connection count detected",
            service_type="local",
            host="database-server",
            status=ServiceStatus.ACTIVE,
            metadata={"connections": 150, "max_connections": 200}
        ),
        LogEntry(
            service_name="nginx",
            log_level=LogLevel.ERROR,
            message="Failed to bind to port 80",
            service_type="remote",
            host="web-server",
            status=ServiceStatus.FAILED,
            metadata={"port": 80, "error_code": "EADDRINUSE"}
        )
    ]

    # Save logs individually
    for log in logs:
        success = log_operations.save_log(log)
        print(f"Saved log for {log.service_name}: {'✓' if success else '✗'}")

    # Save logs in batch
    batch_logs = [
        LogEntry("redis", LogLevel.INFO, "Cache cleared", host="cache-server"),
        LogEntry("postgres", LogLevel.DEBUG, "Query executed", host="db-server"),
    ]

    batch_count = log_operations.save_logs_batch(batch_logs)
    print(f"Batch saved {batch_count} logs")

def demo_event_logging():
    """Demonstrate event logging"""
    print("\n=== Event Logging Demo ===")

    # Create sample events
    events = [
        EventEntry(
            service_name="prometheus",
            event_type="service_restart",
            description="Prometheus service was restarted after configuration change",
            severity=LogLevel.INFO,
            duration=5.2,
            metadata={"reason": "config_update", "downtime_seconds": 5.2}
        ),
        EventEntry(
            service_name="mysql",
            event_type="performance_alert",
            description="Database response time exceeded threshold",
            severity=LogLevel.WARNING,
            metadata={"response_time_ms": 2500, "threshold_ms": 2000}
        )
    ]

    for event in events:
        success = log_operations.save_event(event)
        print(f"Saved event for {event.service_name}: {'✓' if success else '✗'}")

def demo_querying():
    """Demonstrate querying operations"""
    print("\n=== Querying Demo ===")

    # Get recent logs for a service
    prometheus_logs = log_operations.get_recent_logs("prometheus", hours=24)
    print(f"Found {len(prometheus_logs)} recent Prometheus logs")

    # Get error logs
    error_logs = log_operations.get_error_logs(hours=24)
    print(f"Found {len(error_logs)} error/warning logs in last 24h")

    # Get service statistics
    stats = log_operations.get_service_statistics("prometheus", hours=24)
    if stats:
        print(f"Prometheus stats: {stats['total_logs']} total logs")
        print(f"By level: {stats['by_level']}")

    # Query with filters
    filtered_logs = log_operations.get_logs(
        service_name="mysql",
        log_level=LogLevel.WARNING,
        limit=10
    )
    print(f"Found {len(filtered_logs)} MySQL warning logs")

def demo_file_import():
    """Demonstrate importing from existing log files"""
    print("\n=== File Import Demo ===")

    log_file_path = "monitor/logs/service_monitor.log"
    if os.path.exists(log_file_path):
        imported_count = log_operations.import_from_file(log_file_path, host="localhost")
        print(f"Imported {imported_count} logs from {log_file_path}")
    else:
        print(f"Log file not found: {log_file_path}")

def demo_maintenance():
    """Demonstrate maintenance operations"""
    print("\n=== Maintenance Demo ===")

    # Delete old logs (example: keep only 30 days)
    # deleted_count = log_operations.delete_old_logs(days_to_keep=30)
    # print(f"Deleted {deleted_count} old log entries")

    # Check connection health
    connection_info = log_operations.connection.get_connection_info()
    print(f"MongoDB connection: {'✓' if connection_info['connected'] else '✗'}")
    print(f"Database: {connection_info['database_name']}")
    print(f"Healthy: {'✓' if connection_info['healthy'] else '✗'}")

def main():
    """Main demo function"""
    print("MongoDB Logging System Demo")
    print("=" * 40)

    # Check if MongoDB connection is available
    if not log_operations.connection.connect():
        print("❌ Failed to connect to MongoDB")
        print("Make sure MongoDB is running and connection parameters are correct")
        print("Set environment variables:")
        print("  MONGO_HOST (default: localhost)")
        print("  MONGO_PORT (default: 27017)")
        print("  MONGO_USERNAME (optional)")
        print("  MONGO_PASSWORD (optional)")
        return 1

    print("✅ Connected to MongoDB successfully")

    try:
        # Run demos
        demo_basic_logging()
        demo_event_logging()
        demo_querying()
        demo_file_import()
        demo_maintenance()

        print("\n🎉 Demo completed successfully!")
        return 0

    except Exception as e:
        print(f"\n❌ Demo failed: {e}")
        return 1

    finally:
        # Clean up connection
        log_operations.connection.disconnect()

if __name__ == "__main__":
    sys.exit(main())