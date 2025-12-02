import logging
import sys
import os

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from notifications.notification_manager import NotificationManager
from notifications.models import SMSProvider

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_telegram():
    print("Testing Telegram Integration...")
    
    # Initialize Manager
    manager = NotificationManager()
    
    # Test Parameters
    # REPLACE WITH YOUR REAL CREDENTIALS
    bot_token = "YOUR_BOT_TOKEN_HERE"
    chat_id = "YOUR_CHAT_ID_HERE"
    
    # Note: For Telegram, we pass the bot token via environment variable or kwargs
    # But the NotificationManager usually loads from config/env.
    # For this test, we'll set the env var temporarily if not set.
    if bot_token != "YOUR_BOT_TOKEN_HERE":
        os.environ['TELEGRAM_BOT_TOKEN'] = bot_token

    message = "🔔 This is a test notification from your Service Monitor via Telegram!"

    print(f"Sending message to Chat ID {chat_id}...")
    
    # Send Test
    # For Telegram, we pass the chat_id as the phone_number argument
    result = manager.send_test_notification(
        phone_number=chat_id,
        message=message,
        provider=SMSProvider.TELEGRAM
    )
    
    if result['success']:
        print("\n✅ SUCCESS: Message sent to Telegram!")
        print(f"Metadata: {result.get('metadata')}")
    else:
        print("\n❌ FAILED: Could not send message.")
        print(f"Error: {result.get('error')}")
        print("\nTroubleshooting:")
        print("1. Is the Bot Token correct?")
        print("2. Is the Chat ID correct?")
        print("3. Did you start a conversation with the bot first?")

if __name__ == "__main__":
    test_telegram()
