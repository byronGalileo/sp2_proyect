import logging
from typing import Optional

from .base_sms_provider import BaseSMSProvider, SMSProviderType
from .aws_sns_provider import AWSSNSProvider
from .twilio_provider import TwilioProvider


logger = logging.getLogger(__name__)


class SMSProviderFactory:
    """Factory for creating SMS provider instances"""

    _providers = {}

    @classmethod
    def create_provider(
        cls,
        provider_type: SMSProviderType,
        **kwargs
    ) -> Optional[BaseSMSProvider]:
        """
        Create an SMS provider instance

        Args:
            provider_type: Type of provider to create
            **kwargs: Provider-specific initialization parameters

        Returns:
            BaseSMSProvider instance or None if provider type not supported
        """
        if provider_type == SMSProviderType.AWS_SNS:
            return AWSSNSProvider(
                aws_access_key_id=kwargs.get('aws_access_key_id'),
                aws_secret_access_key=kwargs.get('aws_secret_access_key'),
                region_name=kwargs.get('region_name'),
                default_sender_id=kwargs.get('default_sender_id')
            )

        elif provider_type == SMSProviderType.TWILIO:
            return TwilioProvider(
                account_sid=kwargs.get('account_sid'),
                auth_token=kwargs.get('auth_token'),
                from_phone_number=kwargs.get('from_phone_number')
            )

        else:
            logger.error(f"Unsupported SMS provider type: {provider_type}")
            return None

    @classmethod
    def get_or_create_provider(
        cls,
        provider_type: SMSProviderType,
        **kwargs
    ) -> Optional[BaseSMSProvider]:
        """
        Get existing provider instance or create new one (singleton pattern per type)

        Args:
            provider_type: Type of provider
            **kwargs: Provider-specific initialization parameters

        Returns:
            BaseSMSProvider instance
        """
        if provider_type not in cls._providers:
            cls._providers[provider_type] = cls.create_provider(provider_type, **kwargs)

        return cls._providers[provider_type]

    @classmethod
    def clear_providers(cls):
        """Clear all cached provider instances"""
        cls._providers.clear()


def get_sms_provider(
    provider_type: SMSProviderType,
    use_cache: bool = True,
    **kwargs
) -> Optional[BaseSMSProvider]:
    """
    Convenience function to get SMS provider

    Args:
        provider_type: Type of provider (aws_sns, twilio)
        use_cache: Whether to use cached instance (default: True)
        **kwargs: Provider-specific parameters

    Returns:
        BaseSMSProvider instance

    Example:
        >>> provider = get_sms_provider(SMSProviderType.TWILIO)
        >>> result = provider.send_sms("+50212345678", "Test message")
    """
    if use_cache:
        return SMSProviderFactory.get_or_create_provider(provider_type, **kwargs)
    else:
        return SMSProviderFactory.create_provider(provider_type, **kwargs)
