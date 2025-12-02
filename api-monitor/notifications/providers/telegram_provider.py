import logging
import requests
from typing import Dict, Any, Optional
from datetime import datetime

from .base_sms_provider import BaseSMSProvider, SMSProviderType


logger = logging.getLogger(__name__)


class TelegramProvider(BaseSMSProvider):
    """Telegram provider using official Bot API"""

    def __init__(self, bot_token: str):
        """
        Initialize Telegram provider

        Args:
            bot_token: Telegram Bot API Token
        """
        super().__init__()
        self.bot_token = bot_token
        self.api_url = f"https://api.telegram.org/bot{bot_token}"

    def _initialize_client(self) -> bool:
        """Initialize Telegram client (check token validity)"""
        if self._initialized:
            return True

        if not self.bot_token:
            self._init_error = "Bot token not provided"
            return False

        try:
            # Check if token is valid by calling getMe
            response = requests.get(f"{self.api_url}/getMe", timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if not data.get('ok'):
                self._init_error = f"Invalid bot token: {data.get('description')}"
                return False

            bot_info = data.get('result', {})
            logger.info(f"Telegram provider initialized for bot: {bot_info.get('username')}")
            self._initialized = True
            return True

        except Exception as e:
            self._init_error = str(e)
            logger.error(f"Failed to initialize Telegram provider: {e}")
            return False

    def send_sms(
        self,
        phone_number: str,
        message: str,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send Telegram message

        Args:
            phone_number: Chat ID (e.g., "123456789") - Reusing phone_number field for Chat ID
            message: Message text
            **kwargs: Additional parameters

        Returns:
            Dict with success status
        """
        if not self._initialize_client():
            return {
                'success': False,
                'error': f'Telegram provider not available: {self._init_error}',
                'message_id': None,
                'metadata': {'provider': 'telegram'}
            }

        try:
            # In Telegram context, phone_number is treated as chat_id
            chat_id = phone_number

            payload = {
                'chat_id': chat_id,
                'text': message,
                'parse_mode': 'Markdown'  # Optional: support markdown
            }

            response = requests.post(f"{self.api_url}/sendMessage", json=payload, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            if not data.get('ok'):
                return {
                    'success': False,
                    'error': data.get('description', 'Unknown Telegram error'),
                    'message_id': None,
                    'metadata': {'provider': 'telegram'}
                }

            result = data.get('result', {})
            
            return {
                'success': True,
                'error': None,
                'message_id': str(result.get('message_id')),
                'metadata': {
                    'provider': 'telegram',
                    'timestamp': datetime.utcnow().isoformat(),
                    'chat_id': chat_id,
                    'bot_username': result.get('from', {}).get('username')
                }
            }

        except requests.exceptions.RequestException as e:
            error_msg = str(e)
            logger.error(f"Error sending Telegram message to {phone_number}: {error_msg}")
            return {
                'success': False,
                'error': error_msg,
                'message_id': None,
                'metadata': {
                    'provider': 'telegram',
                    'timestamp': datetime.utcnow().isoformat()
                }
            }
        except Exception as e:
            logger.error(f"Unexpected error sending Telegram message: {e}")
            return {
                'success': False,
                'error': str(e),
                'message_id': None,
                'metadata': {'provider': 'telegram'}
            }

    def get_provider_name(self) -> str:
        return "Telegram"

    def get_provider_type(self) -> SMSProviderType:
        return SMSProviderType.TELEGRAM
