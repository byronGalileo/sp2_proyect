import os
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv

# Find and load .env file from project root
def find_and_load_env():
    """Find .env file in project root and load it"""
    current_path = Path(__file__).resolve()

    # Try to find .env in parent directories
    for parent in [current_path.parent] + list(current_path.parents):
        env_file = parent / '.env'
        if env_file.exists():
            load_dotenv(env_file)
            return True

    # Fallback to default load_dotenv behavior
    load_dotenv()
    return False

find_and_load_env()

class MongoConfig:
    """MongoDB configuration management"""

    def __init__(self):
        self.connection_string = self._get_connection_string()
        self.database_name = os.getenv('MONGO_DB_NAME', 'service_monitoring')
        self.logs_collection = os.getenv('MONGO_LOGS_COLLECTION', 'logs')
        self.events_collection = os.getenv('MONGO_EVENTS_COLLECTION', 'events')

    def _get_connection_string(self) -> str:
        """Build MongoDB connection string from environment variables"""
        host = os.getenv('MONGO_HOST', 'localhost')
        # port = os.getenv('MONGO_PORT', '27017')
        username = os.getenv('MONGO_USERNAME')
        password = os.getenv('MONGO_PASSWORD')
        cluster_name = os.getenv('MONGO_CLUSTER', 'Cluster0')

        if username and password:
            return f"mongodb+srv://{username}:{password}@{host}/?retryWrites=true&w=majority&appName={cluster_name}"
        else:
            return f"mongodb://{host}"

    @property
    def connection_options(self) -> dict:
        """MongoDB connection options"""
        return {
            'serverSelectionTimeoutMS': 5000,
            'connectTimeoutMS': 10000,
            'maxPoolSize': 50,
            'retryWrites': True,
            'w': 'majority'
        }