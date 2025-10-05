import os
from typing import Optional

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
        port = os.getenv('MONGO_PORT', '27017')
        username = os.getenv('MONGO_USERNAME')
        password = os.getenv('MONGO_PASSWORD')
        auth_db = os.getenv('MONGO_AUTH_DB', 'admin')

        if username and password:
            return f"mongodb://{username}:{password}@{host}:{port}/{auth_db}"
        else:
            return f"mongodb://{host}:{port}"

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