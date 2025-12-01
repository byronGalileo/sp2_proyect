import logging
from typing import List, Optional, Dict, Any
from datetime import datetime

from .models import (
    NotificationEventType,
    NotificationChannel,
    NotificationStatus,
    NotificationHistory,
    ServiceNotificationConfig,
    SMSProvider
)
from .notification_operations import notification_operations
from .providers import SMSProviderType, get_sms_provider


logger = logging.getLogger(__name__)


class NotificationManager:
    """Manages notification sending across multiple channels"""

    def __init__(self):
        """Initialize notification manager"""
        # Initialize SMS providers (will be created on demand via factory)
        self._sms_providers = {}

        # Ensure database indexes
        notification_operations.ensure_indexes()

        logger.info("Notification manager initialized")

    def send_service_notification(
        self,
        service_name: str,
        host: str,
        event_type: NotificationEventType,
        message: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Send notification for a service event

        Args:
            service_name: Name of the service
            host: Host where service is running
            event_type: Type of event triggering notification
            message: Notification message
            metadata: Additional metadata

        Returns:
            Dict with results: total_sent, total_failed, details
        """
        # Get notification configuration
        config = notification_operations.get_notification_config(service_name, host)

        if not config:
            logger.debug(f"No notification config found for {host}:{service_name}")
            return {
                'sent': 0,
                'failed': 0,
                'skipped': 1,
                'reason': 'No notification configuration found',
                'details': []
            }

        if not config.enabled:
            logger.debug(f"Notifications disabled for {host}:{service_name}")
            return {
                'sent': 0,
                'failed': 0,
                'skipped': 1,
                'reason': 'Notifications disabled for this service',
                'details': []
            }

        # Check cooldown period
        recent_notification = notification_operations.get_recent_notification(
            service_name,
            host,
            event_type,
            minutes=config.cooldown_minutes
        )

        if recent_notification:
            logger.info(
                f"Skipping notification for {host}:{service_name} - "
                f"cooldown period active ({config.cooldown_minutes} minutes)"
            )
            return {
                'sent': 0,
                'failed': 0,
                'skipped': 1,
                'reason': f'Cooldown period active ({config.cooldown_minutes} minutes)',
                'details': []
            }

        # Send notifications to all configured contacts
        results = {
            'sent': 0,
            'failed': 0,
            'skipped': 0,
            'details': []
        }

        for contact in config.contacts:
            if not contact.enabled:
                results['skipped'] += 1
                results['details'].append({
                    'contact': contact.name,
                    'status': 'skipped',
                    'reason': 'Contact disabled'
                })
                continue

            # Check if contact wants this event type
            if event_type not in contact.notify_on:
                results['skipped'] += 1
                results['details'].append({
                    'contact': contact.name,
                    'status': 'skipped',
                    'reason': f'Contact not subscribed to {event_type.value} events'
                })
                continue

            # Send via each enabled channel
            for channel in contact.channels:
                result = self._send_notification(
                    service_name=service_name,
                    host=host,
                    event_type=event_type,
                    channel=channel,
                    contact=contact,
                    message=message,
                    sms_provider=config.sms_provider,
                    metadata=metadata
                )

                if result['success']:
                    results['sent'] += 1
                else:
                    results['failed'] += 1

                results['details'].append(result)

        logger.info(
            f"Notifications for {host}:{service_name} - "
            f"Sent: {results['sent']}, Failed: {results['failed']}, Skipped: {results['skipped']}"
        )

        return results

    def _send_notification(
        self,
        service_name: str,
        host: str,
        event_type: NotificationEventType,
        channel: NotificationChannel,
        contact: Any,
        message: str,
        sms_provider: SMSProvider = SMSProvider.AWS_SNS,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Send a single notification via specified channel"""

        # Create notification history record
        notification = NotificationHistory(
            service_name=service_name,
            host=host,
            event_type=event_type,
            channel=channel,
            recipient=self._get_recipient_identifier(contact, channel),
            message=message,
            status=NotificationStatus.PENDING,
            metadata=metadata or {}
        )

        # Save to database
        saved = notification_operations.save_notification_history(notification)
        if not saved:
            return {
                'success': False,
                'contact': contact.name,
                'channel': channel.value,
                'error': 'Failed to save notification to database'
            }

        # Send via appropriate channel
        if channel == NotificationChannel.SMS:
            result = self._send_sms(contact, message, sms_provider)
        elif channel == NotificationChannel.EMAIL:
            result = self._send_email(contact, message)
        elif channel == NotificationChannel.PUSH:
            result = self._send_push(contact, message)
        else:
            result = {
                'success': False,
                'error': f'Unsupported channel: {channel.value}'
            }

        # Update notification status in database
        # Note: In a real implementation, we'd get the notification ID from save operation
        # For now, we'll just log the result

        return {
            'success': result['success'],
            'contact': contact.name,
            'channel': channel.value,
            'recipient': self._get_recipient_identifier(contact, channel),
            'error': result.get('error'),
            'message_id': result.get('message_id'),
            'metadata': result.get('metadata', {})
        }

    def _get_sms_provider(self, provider_type: SMSProvider):
        """Get SMS provider instance"""
        # Convert SMSProvider enum to SMSProviderType
        if provider_type == SMSProvider.AWS_SNS:
            sms_provider_type = SMSProviderType.AWS_SNS
        elif provider_type == SMSProvider.TWILIO:
            sms_provider_type = SMSProviderType.TWILIO
        elif provider_type == SMSProvider.WHATSAPP:
            sms_provider_type = SMSProviderType.WHATSAPP
        elif provider_type == SMSProvider.TELEGRAM:
            sms_provider_type = SMSProviderType.TELEGRAM
        else:
            return None

        # Get cached provider or create new one
        if provider_type not in self._sms_providers:
            self._sms_providers[provider_type] = get_sms_provider(sms_provider_type, use_cache=True)

        return self._sms_providers[provider_type]

    def _send_sms(self, contact: Any, message: str, provider_type: SMSProvider = SMSProvider.AWS_SNS) -> Dict[str, Any]:
        """Send SMS notification using specified provider"""
        if not contact.phone:
            return {
                'success': False,
                'error': 'No phone number configured for contact'
            }

        # Get SMS provider
        sms_provider = self._get_sms_provider(provider_type)

        if not sms_provider:
            return {
                'success': False,
                'error': f'SMS provider {provider_type.value} not available'
            }

        if not sms_provider.is_available():
            return {
                'success': False,
                'error': f'{sms_provider.get_provider_name()} not available: {sms_provider.get_initialization_error()}'
            }

        return sms_provider.send_sms(contact.phone, message)

    def _send_email(self, contact: Any, message: str) -> Dict[str, Any]:
        """Send email notification (placeholder)"""
        # TODO: Implement email sending via AWS SES or other service
        return {
            'success': False,
            'error': 'Email notifications not yet implemented'
        }

    def _send_push(self, contact: Any, message: str) -> Dict[str, Any]:
        """Send push notification (placeholder)"""
        # TODO: Implement push notifications via Firebase
        return {
            'success': False,
            'error': 'Push notifications not yet implemented'
        }

    def _get_recipient_identifier(self, contact: Any, channel: NotificationChannel) -> str:
        """Get recipient identifier for a channel"""
        if channel == NotificationChannel.SMS:
            return contact.phone or 'no_phone'
        elif channel == NotificationChannel.EMAIL:
            return contact.email or 'no_email'
        elif channel == NotificationChannel.PUSH:
            return contact.name  # For push, we'd normally use device token
        return 'unknown'

    def send_test_notification(
        self,
        phone_number: str,
        message: str = "Test notification from Service Monitor",
        provider: SMSProvider = SMSProvider.AWS_SNS
    ) -> Dict[str, Any]:
        """Send a test SMS notification"""
        sms_provider = self._get_sms_provider(provider)

        if not sms_provider:
            return {
                'success': False,
                'error': f'SMS provider {provider.value} not available'
            }

        if not sms_provider.is_available():
            return {
                'success': False,
                'error': f'{sms_provider.get_provider_name()} not available: {sms_provider.get_initialization_error()}'
            }

        return sms_provider.send_sms(phone_number, message)

    def get_service_status(self) -> Dict[str, Any]:
        """Get status of notification services"""
        # Check both SMS providers
        aws_sns_provider = self._get_sms_provider(SMSProvider.AWS_SNS)
        twilio_provider = self._get_sms_provider(SMSProvider.TWILIO)

        return {
            'sms_providers': {
                'aws_sns': aws_sns_provider.get_provider_info() if aws_sns_provider else {'available': False, 'error': 'Not initialized'},
                'twilio': twilio_provider.get_provider_info() if twilio_provider else {'available': False, 'error': 'Not initialized'},
                'whatsapp': self._get_sms_provider(SMSProvider.WHATSAPP).get_provider_info() if self._get_sms_provider(SMSProvider.WHATSAPP) else {'available': False, 'error': 'Not initialized'},
                'telegram': self._get_sms_provider(SMSProvider.TELEGRAM).get_provider_info() if self._get_sms_provider(SMSProvider.TELEGRAM) else {'available': False, 'error': 'Not initialized'}
            },
            'email': {
                'provider': 'not_implemented',
                'available': False
            },
            'push': {
                'provider': 'not_implemented',
                'available': False
            }
        }


# Helper function to create event-specific messages
def create_notification_message(
    event_type: NotificationEventType,
    service_name: str,
    host: str,
    metadata: Optional[Dict[str, Any]] = None
) -> str:
    """Create a formatted notification message based on event type"""

    if event_type == NotificationEventType.SERVICE_DOWN:
        return (
            f"ALERT: Service '{service_name}' on {host} is DOWN. "
            f"Timestamp: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')} UTC"
        )

    elif event_type == NotificationEventType.SERVICE_RESTART_ATTEMPT:
        attempt = metadata.get('attempt', 1) if metadata else 1
        return (
            f"INFO: Attempting to restart service '{service_name}' on {host}. "
            f"Attempt: {attempt}"
        )

    elif event_type == NotificationEventType.SERVICE_RESTART_FAILED:
        error = metadata.get('error', 'Unknown error') if metadata else 'Unknown error'
        return (
            f"CRITICAL: Failed to restart service '{service_name}' on {host}. "
            f"Error: {error}"
        )

    elif event_type == NotificationEventType.SERVICE_RECOVERED:
        return (
            f"SUCCESS: Service '{service_name}' on {host} has been recovered successfully."
        )

    return f"Notification for service '{service_name}' on {host}: {event_type.value}"
