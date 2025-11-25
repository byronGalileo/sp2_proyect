from datetime import datetime
from typing import Dict, Any, Optional, List
from enum import Enum


class NotificationChannel(Enum):
    """Notification channel types"""
    SMS = "sms"
    EMAIL = "email"
    PUSH = "push"


class NotificationEventType(Enum):
    """Types of events that trigger notifications"""
    SERVICE_DOWN = "service_down"
    SERVICE_RESTART_ATTEMPT = "service_restart_attempt"
    SERVICE_RESTART_FAILED = "service_restart_failed"
    SERVICE_RECOVERED = "service_recovered"


class NotificationStatus(Enum):
    """Status of notification delivery"""
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    RETRY = "retry"


class NotificationContact:
    """Contact information for notifications"""

    def __init__(
        self,
        name: str,
        phone: Optional[str] = None,
        email: Optional[str] = None,
        enabled: bool = True,
        channels: Optional[List[NotificationChannel]] = None,
        notify_on: Optional[List[NotificationEventType]] = None
    ):
        self.name = name
        self.phone = phone
        self.email = email
        self.enabled = enabled
        self.channels = channels or [NotificationChannel.SMS]
        self.notify_on = notify_on or [
            NotificationEventType.SERVICE_DOWN,
            NotificationEventType.SERVICE_RESTART_ATTEMPT,
            NotificationEventType.SERVICE_RESTART_FAILED,
            NotificationEventType.SERVICE_RECOVERED
        ]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for MongoDB storage"""
        return {
            'name': self.name,
            'phone': self.phone,
            'email': self.email,
            'enabled': self.enabled,
            'channels': [channel.value for channel in self.channels],
            'notify_on': [event.value for event in self.notify_on]
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'NotificationContact':
        """Create from dictionary"""
        return cls(
            name=data['name'],
            phone=data.get('phone'),
            email=data.get('email'),
            enabled=data.get('enabled', True),
            channels=[NotificationChannel(ch) for ch in data.get('channels', ['sms'])],
            notify_on=[NotificationEventType(ev) for ev in data.get('notify_on', [])]
        )


class SMSProvider(Enum):
    """SMS provider types"""
    AWS_SNS = "aws_sns"
    TWILIO = "twilio"


class ServiceNotificationConfig:
    """Notification configuration for a service"""

    def __init__(
        self,
        service_name: str,
        host: str,
        contacts: List[NotificationContact],
        enabled: bool = True,
        cooldown_minutes: int = 5,
        sms_provider: SMSProvider = SMSProvider.AWS_SNS,
        metadata: Optional[Dict[str, Any]] = None
    ):
        self.service_name = service_name
        self.host = host
        self.contacts = contacts
        self.enabled = enabled
        self.cooldown_minutes = cooldown_minutes
        self.sms_provider = sms_provider
        self.metadata = metadata or {}

    def to_document(self) -> Dict[str, Any]:
        """Convert to MongoDB document"""
        return {
            'service_name': self.service_name,
            'host': self.host,
            'contacts': [contact.to_dict() for contact in self.contacts],
            'enabled': self.enabled,
            'cooldown_minutes': self.cooldown_minutes,
            'sms_provider': self.sms_provider.value,
            'metadata': self.metadata,
            'service_key': f"{self.host}:{self.service_name}",
            'updated_at': datetime.utcnow()
        }

    @classmethod
    def from_document(cls, doc: Dict[str, Any]) -> 'ServiceNotificationConfig':
        """Create from MongoDB document"""
        # Handle sms_provider with default fallback
        sms_provider_value = doc.get('sms_provider', 'aws_sns')
        try:
            sms_provider = SMSProvider(sms_provider_value)
        except ValueError:
            sms_provider = SMSProvider.AWS_SNS

        return cls(
            service_name=doc['service_name'],
            host=doc['host'],
            contacts=[NotificationContact.from_dict(c) for c in doc.get('contacts', [])],
            enabled=doc.get('enabled', True),
            cooldown_minutes=doc.get('cooldown_minutes', 5),
            sms_provider=sms_provider,
            metadata=doc.get('metadata', {})
        )


class NotificationHistory:
    """Record of a sent notification"""

    def __init__(
        self,
        service_name: str,
        host: str,
        event_type: NotificationEventType,
        channel: NotificationChannel,
        recipient: str,
        message: str,
        status: NotificationStatus = NotificationStatus.PENDING,
        timestamp: Optional[datetime] = None,
        sent_at: Optional[datetime] = None,
        metadata: Optional[Dict[str, Any]] = None,
        error_message: Optional[str] = None
    ):
        self.service_name = service_name
        self.host = host
        self.event_type = event_type
        self.channel = channel
        self.recipient = recipient
        self.message = message
        self.status = status
        self.timestamp = timestamp or datetime.utcnow()
        self.sent_at = sent_at
        self.metadata = metadata or {}
        self.error_message = error_message

    def to_document(self) -> Dict[str, Any]:
        """Convert to MongoDB document"""
        doc = {
            'service_name': self.service_name,
            'host': self.host,
            'event_type': self.event_type.value,
            'channel': self.channel.value,
            'recipient': self.recipient,
            'message': self.message,
            'status': self.status.value,
            'timestamp': self.timestamp,
            'metadata': self.metadata,
            'service_key': f"{self.host}:{self.service_name}",
            'date': self.timestamp.strftime('%Y-%m-%d')
        }

        if self.sent_at:
            doc['sent_at'] = self.sent_at

        if self.error_message:
            doc['error_message'] = self.error_message

        return doc

    @classmethod
    def from_document(cls, doc: Dict[str, Any]) -> 'NotificationHistory':
        """Create from MongoDB document"""
        return cls(
            service_name=doc['service_name'],
            host=doc['host'],
            event_type=NotificationEventType(doc['event_type']),
            channel=NotificationChannel(doc['channel']),
            recipient=doc['recipient'],
            message=doc['message'],
            status=NotificationStatus(doc['status']),
            timestamp=doc['timestamp'],
            sent_at=doc.get('sent_at'),
            metadata=doc.get('metadata', {}),
            error_message=doc.get('error_message')
        )
