"""
Notification Module for Service Monitoring

This module provides notification capabilities for service monitoring events
via multiple channels (SMS, Email, Push notifications).

Key Components:
- models: Data models for notifications (contacts, configs, history)
- notification_operations: Database operations for notification management
- aws_sns_service: AWS SNS integration for SMS notifications
- notification_manager: High-level notification orchestration

Usage:
    from notifications import notification_manager, NotificationEventType, create_notification_message

    # Send a service notification
    message = create_notification_message(
        NotificationEventType.SERVICE_RESTART_ATTEMPT,
        "my-service",
        "localhost"
    )

    result = notification_manager.send_service_notification(
        service_name="my-service",
        host="localhost",
        event_type=NotificationEventType.SERVICE_RESTART_ATTEMPT,
        message=message
    )
"""

from .models import (
    NotificationChannel,
    NotificationEventType,
    NotificationStatus,
    NotificationContact,
    ServiceNotificationConfig,
    NotificationHistory
)

from .notification_operations import notification_operations
from .aws_sns_service import AWSSNSService
from .notification_manager import NotificationManager, create_notification_message

# Global notification manager instance
notification_manager = NotificationManager()

__all__ = [
    # Models
    'NotificationChannel',
    'NotificationEventType',
    'NotificationStatus',
    'NotificationContact',
    'ServiceNotificationConfig',
    'NotificationHistory',
    # Operations
    'notification_operations',
    # Services
    'AWSSNSService',
    'NotificationManager',
    'notification_manager',
    # Helpers
    'create_notification_message'
]

__version__ = "1.0.0"
