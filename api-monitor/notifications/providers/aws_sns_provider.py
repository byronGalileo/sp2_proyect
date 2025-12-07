import os
import logging
from typing import Optional, Dict, Any
from datetime import datetime
import boto3
from botocore.exceptions import ClientError, BotoCoreError

from .base_sms_provider import BaseSMSProvider, SMSProviderType


logger = logging.getLogger(__name__)


class AWSSNSProvider(BaseSMSProvider):
    """AWS SNS SMS provider implementation"""

    def __init__(
        self,
        aws_access_key_id: Optional[str] = None,
        aws_secret_access_key: Optional[str] = None,
        region_name: Optional[str] = None,
        default_sender_id: Optional[str] = None
    ):
        """
        Initialize AWS SNS provider

        Args:
            aws_access_key_id: AWS access key (or will use env var AWS_ACCESS_KEY_ID)
            aws_secret_access_key: AWS secret key (or will use env var AWS_SECRET_ACCESS_KEY)
            region_name: AWS region (or will use env var AWS_REGION, default: us-east-1)
            default_sender_id: Sender ID for SMS (optional, for supported countries)
        """
        super().__init__()
        self.aws_access_key_id = aws_access_key_id or os.getenv('AWS_ACCESS_KEY_ID')
        self.aws_secret_access_key = aws_secret_access_key or os.getenv('AWS_SECRET_ACCESS_KEY')
        self.region_name = region_name or os.getenv('AWS_REGION', 'us-east-1')
        self.default_sender_id = default_sender_id or os.getenv('AWS_SNS_SENDER_ID', 'ServiceMon')
        self._client = None

    def _initialize_client(self) -> bool:
        """Initialize AWS SNS client"""
        if self._initialized:
            return self._client is not None

        try:
            if not self.aws_access_key_id or not self.aws_secret_access_key:
                self._init_error = "AWS credentials not provided"
                logger.error("AWS SNS: Credentials not configured")
                self._initialized = True
                return False

            self._client = boto3.client(
                'sns',
                aws_access_key_id=self.aws_access_key_id,
                aws_secret_access_key=self.aws_secret_access_key,
                region_name=self.region_name
            )

            # Test connection
            self._client.get_sms_attributes()

            self._initialized = True
            logger.info(f"AWS SNS provider initialized successfully in region {self.region_name}")
            return True

        except (ClientError, BotoCoreError) as e:
            self._init_error = str(e)
            logger.error(f"Failed to initialize AWS SNS provider: {e}")
            self._initialized = True
            return False
        except Exception as e:
            self._init_error = str(e)
            logger.error(f"Unexpected error initializing AWS SNS: {e}")
            self._initialized = True
            return False

    def send_sms(
        self,
        phone_number: str,
        message: str,
        sender_id: Optional[str] = None,
        message_attributes: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Send SMS via AWS SNS

        Args:
            phone_number: Phone number in E.164 format (e.g., +50212345678)
            message: Message text (max 160 chars for single SMS)
            sender_id: Custom sender ID (optional, not supported in all countries)
            message_attributes: Additional message attributes

        Returns:
            Dict with success status, message_id, and metadata
        """
        if not self._initialize_client():
            return {
                'success': False,
                'error': f'AWS SNS not available: {self._init_error}',
                'message_id': None,
                'metadata': {
                    'provider': 'aws_sns',
                    'timestamp': datetime.utcnow().isoformat()
                }
            }

        try:
            # Validate phone number format
            if not phone_number.startswith('+'):
                return {
                    'success': False,
                    'error': 'Phone number must be in E.164 format (e.g., +50212345678)',
                    'message_id': None,
                    'metadata': {'provider': 'aws_sns'}
                }

            # Prepare message attributes
            attrs = {
                'AWS.SNS.SMS.SMSType': {
                    'DataType': 'String',
                    'StringValue': 'Transactional'
                }
            }

            # Add sender ID if provided
            sender = sender_id or self.default_sender_id
            if sender:
                attrs['AWS.SNS.SMS.SenderID'] = {
                    'DataType': 'String',
                    'StringValue': sender[:11]
                }

            # Add custom attributes
            if message_attributes:
                attrs.update(message_attributes)

            # Send SMS
            response = self._client.publish(
                PhoneNumber=phone_number,
                Message=message,
                MessageAttributes=attrs
            )

            message_id = response.get('MessageId')
            logger.info(f"AWS SNS: SMS sent to {phone_number}, MessageId: {message_id}")

            return {
                'success': True,
                'error': None,
                'message_id': message_id,
                'metadata': {
                    'provider': 'aws_sns',
                    'region': self.region_name,
                    'timestamp': datetime.utcnow().isoformat(),
                    'response_metadata': response.get('ResponseMetadata', {})
                }
            }

        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            error_message = e.response.get('Error', {}).get('Message', str(e))
            logger.error(f"AWS SNS ClientError sending SMS to {phone_number}: {error_code} - {error_message}")

            return {
                'success': False,
                'error': f'{error_code}: {error_message}',
                'message_id': None,
                'metadata': {
                    'provider': 'aws_sns',
                    'error_code': error_code,
                    'timestamp': datetime.utcnow().isoformat()
                }
            }

        except Exception as e:
            logger.error(f"Unexpected error sending SMS via AWS SNS to {phone_number}: {e}")
            return {
                'success': False,
                'error': str(e),
                'message_id': None,
                'metadata': {
                    'provider': 'aws_sns',
                    'timestamp': datetime.utcnow().isoformat()
                }
            }

    def get_provider_name(self) -> str:
        """Get provider name"""
        return "AWS SNS"

    def get_provider_type(self) -> SMSProviderType:
        """Get provider type"""
        return SMSProviderType.AWS_SNS

    def get_sms_spending(self) -> Dict[str, Any]:
        """Get SMS spending information"""
        if not self._initialize_client():
            return {'success': False, 'error': self._init_error}

        try:
            response = self._client.get_sms_attributes(
                attributes=['MonthlySpendLimit', 'DeliveryStatusIAMRole']
            )

            attributes = response.get('attributes', {})
            return {
                'success': True,
                'monthly_spend_limit': attributes.get('MonthlySpendLimit', 'Not set'),
                'attributes': attributes
            }

        except Exception as e:
            logger.error(f"Error getting SMS spending info: {e}")
            return {'success': False, 'error': str(e)}

    def set_sms_spending_limit(self, limit_usd: float) -> Dict[str, Any]:
        """Set monthly SMS spending limit"""
        if not self._initialize_client():
            return {'success': False, 'error': self._init_error}

        try:
            self._client.set_sms_attributes(
                attributes={
                    'MonthlySpendLimit': str(limit_usd)
                }
            )

            logger.info(f"SMS spending limit set to ${limit_usd}")
            return {
                'success': True,
                'monthly_spend_limit': limit_usd
            }

        except Exception as e:
            logger.error(f"Error setting SMS spending limit: {e}")
            return {'success': False, 'error': str(e)}
