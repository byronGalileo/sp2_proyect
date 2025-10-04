"""
MongoDB Database Module for Service Monitoring

This module provides a scalable MongoDB structure for saving and querying
service monitoring logs and events.

Key Components:
- models: Data models for logs and events
- connection: MongoDB connection management
- operations: Database operations (save, query, statistics)
- config: Configuration management

Usage:
    from database import log_operations, LogEntry, LogLevel

    # Create a log entry
    log = LogEntry(
        service_name="prometheus",
        log_level=LogLevel.INFO,
        message="Service is running",
        host="localhost"
    )

    # Save to MongoDB
    log_operations.save_log(log)

    # Query logs
    recent_logs = log_operations.get_recent_logs("prometheus", hours=24)
"""

from .models import LogEntry, EventEntry, LogLevel, ServiceStatus, ServiceStatus
from .connection import mongo_connection
from .operations import log_operations
from .config import MongoConfig

__all__ = [
    'LogEntry',
    'EventEntry',
    'LogLevel',
    'ServiceStatus',
    'mongo_connection',
    'log_operations',
    'MongoConfig'
]

__version__ = "1.0.0"