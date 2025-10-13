import logging
from typing import Optional
from pymongo import MongoClient
from pymongo.database import Database
from pymongo.collection import Collection
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
from .config import MongoConfig

logger = logging.getLogger(__name__)

class MongoConnection:
    """MongoDB connection manager with singleton pattern"""

    _instance: Optional['MongoConnection'] = None
    _client: Optional[MongoClient] = None
    _database: Optional[Database] = None

    def __new__(cls) -> 'MongoConnection':
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if not hasattr(self, '_initialized'):
            self.config = MongoConfig()
            self._initialized = True

    def connect(self) -> bool:
        """Establish connection to MongoDB"""
        try:
            if self._client is None:
                logger.info(f"Connecting to MongoDB at {self.config.connection_string}")
                self._client = MongoClient(
                    self.config.connection_string,
                    **self.config.connection_options
                )

                # Test connection
                self._client.server_info()

                self._database = self._client[self.config.database_name]

                # Create indexes for better performance
                self._create_indexes()

                logger.info("Successfully connected to MongoDB")
                return True

        except (ConnectionFailure, ServerSelectionTimeoutError) as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            self._client = None
            self._database = None
            return False

    def disconnect(self):
        """Close MongoDB connection"""
        if self._client:
            self._client.close()
            self._client = None
            self._database = None
            logger.info("Disconnected from MongoDB")

    def _create_indexes(self):
        """Create database indexes for optimal performance"""
        if self._database is None:
            return

        try:
            # Logs collection indexes
            logs_collection = self._database[self.config.logs_collection]
            logs_collection.create_index("timestamp")
            logs_collection.create_index("service_name")
            logs_collection.create_index("service_key")
            logs_collection.create_index("log_level")
            logs_collection.create_index([("service_name", 1), ("timestamp", -1)])
            logs_collection.create_index([("date", 1), ("service_name", 1)])
            logs_collection.create_index("host")

            # Events collection indexes
            events_collection = self._database[self.config.events_collection]
            events_collection.create_index("timestamp")
            events_collection.create_index("service_name")
            events_collection.create_index("service_key")
            events_collection.create_index("event_type")
            events_collection.create_index([("service_name", 1), ("timestamp", -1)])

            # Hosts collection indexes (new)
            hosts_collection = self._database['hosts']
            hosts_collection.create_index("host_id", unique=True)
            hosts_collection.create_index([("environment", 1), ("region", 1)])
            hosts_collection.create_index("status")
            hosts_collection.create_index("metadata.tags")
            hosts_collection.create_index("ip_address")
            hosts_collection.create_index("hostname")

            # Services collection indexes (new)
            services_collection = self._database['services']
            services_collection.create_index("service_id", unique=True)
            services_collection.create_index("host_id")
            services_collection.create_index("service_type")
            services_collection.create_index([("environment", 1), ("service_type", 1)])
            services_collection.create_index("current_status")
            services_collection.create_index([("monitoring.enabled", 1), ("current_status", 1)])
            services_collection.create_index("region")
            services_collection.create_index("tags")
            services_collection.create_index("last_check")

            # Monitoring history collection indexes (new)
            monitoring_history_collection = self._database['monitoring_history']
            monitoring_history_collection.create_index([("service_id", 1), ("timestamp", -1)])
            monitoring_history_collection.create_index([("host_id", 1), ("timestamp", -1)])
            monitoring_history_collection.create_index([("timestamp", -1)])
            monitoring_history_collection.create_index([("status", 1), ("timestamp", -1)])
            monitoring_history_collection.create_index([("check_type", 1), ("timestamp", -1)])
            # TTL index for automatic document expiration (30 days)
            monitoring_history_collection.create_index("expires_at", expireAfterSeconds=0)

            logger.info("Database indexes created successfully")

        except Exception as e:
            logger.warning(f"Failed to create indexes: {e}")

    @property
    def database(self) -> Optional[Database]:
        """Get database instance"""
        if self._database is None:
            self.connect()
        return self._database

    @property
    def logs_collection(self) -> Optional[Collection]:
        """Get logs collection"""
        db = self.database
        if db is not None:
            return db[self.config.logs_collection]
        return None

    @property
    def events_collection(self) -> Optional[Collection]:
        """Get events collection"""
        db = self.database
        if db is not None:
            return db[self.config.events_collection]
        return None

    def health_check(self) -> bool:
        """Check if MongoDB connection is healthy"""
        try:
            if self._client:
                self._client.server_info()
                return True
        except Exception as e:
            logger.error(f"MongoDB health check failed: {e}")
        return False

    def get_connection_info(self) -> dict:
        """Get connection information"""
        return {
            'connected': self._client is not None,
            'database_name': self.config.database_name,
            'logs_collection': self.config.logs_collection,
            'events_collection': self.config.events_collection,
            'healthy': self.health_check()
        }

# Global connection instance
mongo_connection = MongoConnection()