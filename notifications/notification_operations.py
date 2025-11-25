from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from pymongo import ASCENDING, DESCENDING
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database.connection import mongo_connection
from .models import (
    ServiceNotificationConfig,
    NotificationHistory,
    NotificationStatus,
    NotificationEventType,
    NotificationChannel
)


class NotificationOperations:
    """Database operations for notifications"""

    def __init__(self):
        self.connection = mongo_connection
        self.config_collection_name = "notification_configs"
        self.history_collection_name = "notification_history"

    def _get_config_collection(self):
        """Get notification config collection"""
        if self.connection.database is None:
            return None
        return self.connection.database[self.config_collection_name]

    def _get_history_collection(self):
        """Get notification history collection"""
        if self.connection.database is None:
            return None
        return self.connection.database[self.history_collection_name]

    def ensure_indexes(self):
        """Create indexes for notification collections"""
        try:
            # Config collection indexes
            config_coll = self._get_config_collection()
            config_coll.create_index([("service_key", ASCENDING)], unique=True)
            config_coll.create_index([("service_name", ASCENDING)])
            config_coll.create_index([("host", ASCENDING)])
            config_coll.create_index([("enabled", ASCENDING)])

            # History collection indexes
            history_coll = self._get_history_collection()
            history_coll.create_index([("service_key", ASCENDING), ("timestamp", DESCENDING)])
            history_coll.create_index([("timestamp", DESCENDING)])
            history_coll.create_index([("status", ASCENDING)])
            history_coll.create_index([("recipient", ASCENDING)])
            history_coll.create_index([("event_type", ASCENDING)])
            history_coll.create_index([("date", ASCENDING)])

            return True
        except Exception as e:
            print(f"Error creating notification indexes: {e}")
            return False

    # Configuration operations
    def save_notification_config(self, config: ServiceNotificationConfig) -> bool:
        """Save or update notification configuration"""
        try:
            collection = self._get_config_collection()
            if collection is None:
                print("Notification config collection not available")
                return False
            result = collection.update_one(
                {'service_key': f"{config.host}:{config.service_name}"},
                {'$set': config.to_document()},
                upsert=True
            )
            return result.acknowledged
        except Exception as e:
            print(f"Error saving notification config: {e}")
            return False

    def get_notification_config(self, service_name: str, host: str) -> Optional[ServiceNotificationConfig]:
        """Get notification configuration for a service"""
        try:
            collection = self._get_config_collection()
            if collection is None:
                print("Notification config collection not available")
                return None
            doc = collection.find_one({'service_key': f"{host}:{service_name}"})
            if doc:
                return ServiceNotificationConfig.from_document(doc)
            return None
        except Exception as e:
            print(f"Error getting notification config: {e}")
            return None

    def get_all_notification_configs(self, enabled_only: bool = False) -> List[ServiceNotificationConfig]:
        """Get all notification configurations"""
        try:
            collection = self._get_config_collection()
            if collection is None:
                print("Notification config collection not available")
                return []
            query = {'enabled': True} if enabled_only else {}
            docs = collection.find(query)
            return [ServiceNotificationConfig.from_document(doc) for doc in docs]
        except Exception as e:
            print(f"Error getting notification configs: {e}")
            return []

    def delete_notification_config(self, service_name: str, host: str) -> bool:
        """Delete notification configuration"""
        try:
            collection = self._get_config_collection()
            if collection is None:
                print("Notification config collection not available")
                return False
            result = collection.delete_one({'service_key': f"{host}:{service_name}"})
            return result.deleted_count > 0
        except Exception as e:
            print(f"Error deleting notification config: {e}")
            return False

    def update_notification_config_status(self, service_name: str, host: str, enabled: bool) -> bool:
        """Enable or disable notifications for a service"""
        try:
            collection = self._get_config_collection()
            if collection is None:
                print("Notification config collection not available")
                return False
            result = collection.update_one(
                {'service_key': f"{host}:{service_name}"},
                {'$set': {'enabled': enabled, 'updated_at': datetime.utcnow()}}
            )
            return result.modified_count > 0
        except Exception as e:
            print(f"Error updating notification config status: {e}")
            return False

    # History operations
    def save_notification_history(self, notification: NotificationHistory) -> bool:
        """Save notification to history"""
        try:
            collection = self._get_history_collection()
            if collection is None:
                print("Notification history collection not available")
                return False
            result = collection.insert_one(notification.to_document())
            return result.acknowledged
        except Exception as e:
            print(f"Error saving notification history: {e}")
            return False

    def update_notification_status(
        self,
        notification_id: str,
        status: NotificationStatus,
        error_message: Optional[str] = None
    ) -> bool:
        """Update notification status"""
        try:
            from bson import ObjectId
            collection = self._get_history_collection()
            if collection is None:
                print("Notification history collection not available")
                return False
            update_doc = {
                'status': status.value,
            }
            if status == NotificationStatus.SENT:
                update_doc['sent_at'] = datetime.utcnow()
            if error_message:
                update_doc['error_message'] = error_message

            result = collection.update_one(
                {'_id': ObjectId(notification_id)},
                {'$set': update_doc}
            )
            return result.modified_count > 0
        except Exception as e:
            print(f"Error updating notification status: {e}")
            return False

    def get_notification_history(
        self,
        service_name: Optional[str] = None,
        host: Optional[str] = None,
        event_type: Optional[NotificationEventType] = None,
        status: Optional[NotificationStatus] = None,
        hours: int = 24,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Get notification history with filters"""
        try:
            collection = self._get_history_collection()
            if collection is None:
                print("Notification history collection not available")
                return []

            # Build query
            query = {}
            if service_name:
                query['service_name'] = service_name
            if host:
                query['host'] = host
            if event_type:
                query['event_type'] = event_type.value
            if status:
                query['status'] = status.value

            # Time filter
            start_time = datetime.utcnow() - timedelta(hours=hours)
            query['timestamp'] = {'$gte': start_time}

            # Execute query
            cursor = collection.find(query).sort('timestamp', DESCENDING).limit(limit)

            # Convert to list and add string ID
            results = []
            for doc in cursor:
                doc['id'] = str(doc['_id'])
                del doc['_id']
                results.append(doc)

            return results
        except Exception as e:
            print(f"Error getting notification history: {e}")
            return []

    def get_recent_notification(
        self,
        service_name: str,
        host: str,
        event_type: NotificationEventType,
        minutes: int = 5
    ) -> Optional[Dict[str, Any]]:
        """Check if a similar notification was sent recently (for cooldown)"""
        try:
            collection = self._get_history_collection()
            if collection is None:
                print("Notification history collection not available")
                return None

            cutoff_time = datetime.utcnow() - timedelta(minutes=minutes)
            query = {
                'service_key': f"{host}:{service_name}",
                'event_type': event_type.value,
                'status': NotificationStatus.SENT.value,
                'sent_at': {'$gte': cutoff_time}
            }

            doc = collection.find_one(query, sort=[('sent_at', DESCENDING)])
            if doc:
                doc['id'] = str(doc['_id'])
                del doc['_id']
            return doc
        except Exception as e:
            print(f"Error checking recent notification: {e}")
            return None

    def get_notification_stats(self, hours: int = 24) -> Dict[str, Any]:
        """Get notification statistics"""
        try:
            collection = self._get_history_collection()
            if collection is None:
                print("Notification history collection not available")
                return {'total': 0, 'by_status': {}, 'by_channel': {}, 'period_hours': hours}

            start_time = datetime.utcnow() - timedelta(hours=hours)

            pipeline = [
                {'$match': {'timestamp': {'$gte': start_time}}},
                {'$group': {
                    '_id': {
                        'status': '$status',
                        'channel': '$channel'
                    },
                    'count': {'$sum': 1}
                }}
            ]

            results = list(collection.aggregate(pipeline))

            # Format results
            stats = {
                'total': 0,
                'by_status': {},
                'by_channel': {},
                'period_hours': hours
            }

            for result in results:
                count = result['count']
                status = result['_id']['status']
                channel = result['_id']['channel']

                stats['total'] += count
                stats['by_status'][status] = stats['by_status'].get(status, 0) + count
                stats['by_channel'][channel] = stats['by_channel'].get(channel, 0) + count

            return stats
        except Exception as e:
            print(f"Error getting notification stats: {e}")
            return {'total': 0, 'by_status': {}, 'by_channel': {}, 'period_hours': hours}


# Global instance
notification_operations = NotificationOperations()
