"""
MongoDB Database Module for Service Monitoring

This module provides a scalable MongoDB structure for saving and querying
service monitoring logs, events, hosts, services, and monitoring history.

Key Components:
- models: Data models for logs and events (legacy)
- monitoring_models: Data models for hosts, services, and monitoring history
- connection: MongoDB connection management
- operations: Database operations (save, query, statistics)
- host_operations: Host management operations
- service_operations: Service management operations
- monitoring_operations: Monitoring history operations
- config: Configuration management

Usage:
    # Legacy logging
    from database import log_operations, LogEntry, LogLevel

    # Host and Service management
    from database import host_operations, service_operations
    from database.monitoring_models import Host, Service
"""

from .models import LogEntry, EventEntry, LogLevel, ServiceStatus
from .monitoring_models import (
    Host, Service, MonitoringHistory,
    HostStatus, ServiceStatus as MonitoringServiceStatus,
    MonitoringMethod, RecoveryAction, CheckType
)
from .connection import mongo_connection
from .operations import log_operations
from .host_operations import host_operations
from .service_operations import service_operations
from .monitoring_operations import monitoring_operations
from .config import MongoConfig

__all__ = [
    # Legacy models
    'LogEntry',
    'EventEntry',
    'LogLevel',
    'ServiceStatus',
    # Monitoring models
    'Host',
    'Service',
    'MonitoringHistory',
    'HostStatus',
    'MonitoringServiceStatus',
    'MonitoringMethod',
    'RecoveryAction',
    'CheckType',
    # Operations
    'mongo_connection',
    'log_operations',
    'host_operations',
    'service_operations',
    'monitoring_operations',
    # Config
    'MongoConfig'
]

__version__ = "2.0.0"