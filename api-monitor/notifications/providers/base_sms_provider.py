from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from enum import Enum


class SMSProviderType(Enum):
    """SMS provider types"""
    AWS_SNS = "aws_sns"
    TWILIO = "twilio"
    WHATSAPP = "whatsapp"
    TELEGRAM = "telegram"


class BaseSMSProvider(ABC):
    """Abstract base class for SMS providers"""

    def __init__(self):
        self._initialized = False
        self._init_error = None

    @abstractmethod
    def _initialize_client(self) -> bool:
        """
        Initialize the SMS provider client

        Returns:
            bool: True if initialization successful, False otherwise
        """
        pass

    @abstractmethod
    def send_sms(
        self,
        phone_number: str,
        message: str,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Send SMS message

        Args:
            phone_number: Phone number in E.164 format (e.g., +50212345678)
            message: Message text
            **kwargs: Provider-specific parameters

        Returns:
            Dict with keys:
                - success (bool): Whether send was successful
                - error (str|None): Error message if failed
                - message_id (str|None): Provider's message ID
                - metadata (dict): Additional provider-specific metadata
        """
        pass

    def is_available(self) -> bool:
        """
        Check if provider is available and configured

        Returns:
            bool: True if provider is ready to send SMS
        """
        return self._initialize_client()

    def get_initialization_error(self) -> Optional[str]:
        """
        Get initialization error message if any

        Returns:
            Optional[str]: Error message or None
        """
        return self._init_error

    @abstractmethod
    def get_provider_name(self) -> str:
        """
        Get provider name

        Returns:
            str: Provider name (e.g., "AWS SNS", "Twilio")
        """
        pass

    @abstractmethod
    def get_provider_type(self) -> SMSProviderType:
        """
        Get provider type enum

        Returns:
            SMSProviderType: Provider type
        """
        pass

    def get_provider_info(self) -> Dict[str, Any]:
        """
        Get provider information and status

        Returns:
            Dict with provider information
        """
        return {
            'name': self.get_provider_name(),
            'type': self.get_provider_type().value,
            'available': self.is_available(),
            'error': self.get_initialization_error()
        }
