import os
import logging
from typing import Optional, Dict, Any
from datetime import datetime

from .base_sms_provider import BaseSMSProvider, SMSProviderType


logger = logging.getLogger(__name__)


class TwilioProvider(BaseSMSProvider):
    """Twilio SMS provider implementation"""

    def __init__(
        self,
        account_sid: Optional[str] = None,
        auth_token: Optional[str] = None,
        from_phone_number: Optional[str] = None
    ):
        """
        Initialize Twilio provider

        Args:
            account_sid: Twilio Account SID (or will use env var TWILIO_ACCOUNT_SID)
            auth_token: Twilio Auth Token (or will use env var TWILIO_AUTH_TOKEN)
            from_phone_number: Twilio phone number to send from (or will use env var TWILIO_PHONE_NUMBER)
        """
        super().__init__()
        self.account_sid = account_sid or os.getenv('TWILIO_ACCOUNT_SID')
        self.auth_token = auth_token or os.getenv('TWILIO_AUTH_TOKEN')
        self.from_phone_number = from_phone_number or os.getenv('TWILIO_PHONE_NUMBER')
        self._client = None

    def _initialize_client(self) -> bool:
        """Initialize Twilio client"""
        if self._initialized:
            return self._client is not None

        try:
            if not self.account_sid or not self.auth_token:
                self._init_error = "Twilio credentials not provided (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)"
                logger.error("Twilio: Credentials not configured")
                self._initialized = True
                return False

            if not self.from_phone_number:
                self._init_error = "Twilio from phone number not provided (TWILIO_PHONE_NUMBER)"
                logger.error("Twilio: From phone number not configured")
                self._initialized = True
                return False

            # Import Twilio client
            try:
                from twilio.rest import Client
            except ImportError:
                self._init_error = "Twilio SDK not installed. Run: pip install twilio"
                logger.error("Twilio SDK not installed")
                self._initialized = True
                return False

            # Initialize client
            self._client = Client(self.account_sid, self.auth_token)

            # Test connection by fetching account info
            account = self._client.api.accounts(self.account_sid).fetch()

            self._initialized = True
            logger.info(f"Twilio provider initialized successfully for account {account.friendly_name}")
            return True

        except Exception as e:
            self._init_error = str(e)
            logger.error(f"Failed to initialize Twilio provider: {e}")
            self._initialized = True
            return False

    def send_sms(
        self,
        phone_number: str,
        message: str,
        from_number: Optional[str] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send SMS via Twilio

        Args:
            phone_number: Recipient phone number in E.164 format (e.g., +50212345678)
            message: Message text
            from_number: Override default from number (optional)
            **kwargs: Additional Twilio parameters (status_callback, etc.)

        Returns:
            Dict with success status, message_id, and metadata
        """
        if not self._initialize_client():
            return {
                'success': False,
                'error': f'Twilio not available: {self._init_error}',
                'message_id': None,
                'metadata': {
                    'provider': 'twilio',
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
                    'metadata': {'provider': 'twilio'}
                }

            # Use provided from_number or default
            from_num = from_number or self.from_phone_number

            # Send SMS
            twilio_message = self._client.messages.create(
                body=message,
                from_=from_num,
                to=phone_number,
                **kwargs
            )

            logger.info(f"Twilio: SMS sent to {phone_number}, SID: {twilio_message.sid}")

            return {
                'success': True,
                'error': None,
                'message_id': twilio_message.sid,
                'metadata': {
                    'provider': 'twilio',
                    'status': twilio_message.status,
                    'price': twilio_message.price,
                    'price_unit': twilio_message.price_unit,
                    'from': twilio_message.from_,
                    'to': twilio_message.to,
                    'num_segments': twilio_message.num_segments,
                    'timestamp': datetime.utcnow().isoformat()
                }
            }

        except Exception as e:
            error_message = str(e)
            logger.error(f"Error sending SMS via Twilio to {phone_number}: {error_message}")

            # Extract Twilio-specific error info if available
            error_code = None
            if hasattr(e, 'code'):
                error_code = e.code
            if hasattr(e, 'msg'):
                error_message = e.msg

            return {
                'success': False,
                'error': error_message,
                'message_id': None,
                'metadata': {
                    'provider': 'twilio',
                    'error_code': error_code,
                    'timestamp': datetime.utcnow().isoformat()
                }
            }

    def get_provider_name(self) -> str:
        """Get provider name"""
        return "Twilio"

    def get_provider_type(self) -> SMSProviderType:
        """Get provider type"""
        return SMSProviderType.TWILIO

    def get_message_status(self, message_sid: str) -> Dict[str, Any]:
        """
        Get status of a sent message

        Args:
            message_sid: Twilio message SID

        Returns:
            Dict with message status information
        """
        if not self._initialize_client():
            return {'success': False, 'error': self._init_error}

        try:
            message = self._client.messages(message_sid).fetch()

            return {
                'success': True,
                'sid': message.sid,
                'status': message.status,
                'to': message.to,
                'from': message.from_,
                'body': message.body,
                'price': message.price,
                'price_unit': message.price_unit,
                'error_code': message.error_code,
                'error_message': message.error_message,
                'date_created': message.date_created.isoformat() if message.date_created else None,
                'date_sent': message.date_sent.isoformat() if message.date_sent else None,
                'date_updated': message.date_updated.isoformat() if message.date_updated else None
            }

        except Exception as e:
            logger.error(f"Error fetching message status: {e}")
            return {'success': False, 'error': str(e)}

    def get_account_balance(self) -> Dict[str, Any]:
        """Get Twilio account balance"""
        if not self._initialize_client():
            return {'success': False, 'error': self._init_error}

        try:
            balance = self._client.api.balance.fetch()

            return {
                'success': True,
                'currency': balance.currency,
                'balance': balance.balance
            }

        except Exception as e:
            logger.error(f"Error fetching account balance: {e}")
            return {'success': False, 'error': str(e)}
