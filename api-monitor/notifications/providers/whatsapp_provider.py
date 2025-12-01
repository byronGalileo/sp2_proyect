import logging
import requests
from typing import Dict, Any, Optional
from datetime import datetime

from .base_sms_provider import BaseSMSProvider, SMSProviderType


logger = logging.getLogger(__name__)


class WhatsAppProvider(BaseSMSProvider):
    """WhatsApp provider using local WA-BOT microservice"""

    def __init__(self, api_url: str = "http://localhost:3000"):
        """
        Initialize WhatsApp provider

        Args:
            api_url: URL of the WA-BOT microservice
        """
        super().__init__()
        self.api_url = api_url.rstrip('/')

    def _initialize_client(self) -> bool:
        """Initialize WhatsApp client (check connectivity to microservice)"""
        if self._initialized:
            return True

        try:
            # Simple health check or just assume it's up if we can reach it
            # Since WA-BOT doesn't have a specific health endpoint yet, we'll assume it's fine
            # or try to hit the root/send endpoint with a dummy check if possible.
            # For now, we'll just mark as initialized.
            # In a real scenario, we might want to ping it.
            self._initialized = True
            logger.info(f"WhatsApp provider initialized with URL {self.api_url}")
            return True

        except Exception as e:
            self._init_error = str(e)
            logger.error(f"Failed to initialize WhatsApp provider: {e}")
            return False

    def send_sms(
        self,
        phone_number: str,
        message: str,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send WhatsApp message via microservice

        Args:
            phone_number: Phone number (e.g., 1234567890@s.whatsapp.net or just number)
            message: Message text
            **kwargs: Additional parameters

        Returns:
            Dict with success status
        """
        if not self._initialize_client():
            return {
                'success': False,
                'error': f'WhatsApp provider not available: {self._init_error}',
                'message_id': None,
                'metadata': {'provider': 'whatsapp'}
            }

        try:
            # Format phone number if needed
            # WA-BOT/Baileys usually expects '1234567890@s.whatsapp.net'
            # If the user passes just the number, we might need to append suffix.
            # However, let's assume the user configures the full ID or the microservice handles it.
            # Based on WA-BOT code: `sock.sendMessage(recipient, ...)`
            # Recipient should be JID.
            
            recipient = phone_number
            if '@' not in recipient:
                # Basic cleanup and append suffix if missing
                clean_number = recipient.replace('+', '').replace(' ', '').replace('-', '')
                recipient = f"{clean_number}@s.whatsapp.net"

            payload = {
                'phone': recipient,
                'message': message
            }

            response = requests.post(f"{self.api_url}/send-message", json=payload, timeout=10)
            response.raise_for_status()

            return {
                'success': True,
                'error': None,
                'message_id': None,  # WA-BOT might return ID in future
                'metadata': {
                    'provider': 'whatsapp',
                    'timestamp': datetime.utcnow().isoformat(),
                    'api_url': self.api_url
                }
            }

        except requests.exceptions.RequestException as e:
            error_msg = str(e)
            logger.error(f"Error sending WhatsApp message to {phone_number}: {error_msg}")
            return {
                'success': False,
                'error': error_msg,
                'message_id': None,
                'metadata': {
                    'provider': 'whatsapp',
                    'timestamp': datetime.utcnow().isoformat()
                }
            }
        except Exception as e:
            logger.error(f"Unexpected error sending WhatsApp message: {e}")
            return {
                'success': False,
                'error': str(e),
                'message_id': None,
                'metadata': {'provider': 'whatsapp'}
            }

    def get_provider_name(self) -> str:
        return "WhatsApp (WA-BOT)"

    def get_provider_type(self) -> SMSProviderType:
        return SMSProviderType.WHATSAPP
