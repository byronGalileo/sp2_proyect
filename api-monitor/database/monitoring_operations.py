"""
MongoDB operations for Monitoring History management
"""

import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from pymongo.errors import PyMongoError
from pymongo import DESCENDING
from .connection import mongo_connection
from .monitoring_models import MonitoringHistory, CheckType

logger = logging.getLogger(__name__)


class MonitoringOperations:
    """MongoDB operations for monitoring history management"""

    def __init__(self):
        self.connection = mongo_connection

    @property
    def monitoring_history_collection(self):
        """Get monitoring_history collection"""
        if self.connection.database is None:
            return None
        return self.connection.database['monitoring_history']

    def log_check(self, history: MonitoringHistory) -> Optional[str]:
        """
        Log a monitoring check result

        Args:
            history: MonitoringHistory object

        Returns:
            Document ID if successful, None otherwise
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return None

            document = history.to_document()
            result = collection.insert_one(document)

            if result.inserted_id:
                logger.debug(f"Monitoring check logged for service: {history.service_id}")
                return str(result.inserted_id)
            else:
                logger.error("Failed to log monitoring check")
                return None

        except PyMongoError as e:
            logger.error(f"MongoDB error logging check: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error logging check: {e}")
            return None

    def get_service_history(
        self,
        service_id: str,
        limit: int = 100,
        hours: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Get monitoring history for a service

        Args:
            service_id: Service identifier
            limit: Maximum number of records
            hours: Only get history from last N hours

        Returns:
            List of history documents
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return []

            query_filter = {"service_id": service_id}

            # Add time filter if specified
            if hours:
                since = datetime.utcnow() - timedelta(hours=hours)
                query_filter["timestamp"] = {"$gte": since}

            cursor = collection.find(query_filter).sort("timestamp", DESCENDING).limit(limit)
            history = list(cursor)

            # Convert ObjectId to string
            for record in history:
                if '_id' in record:
                    record['_id'] = str(record['_id'])

            return history

        except PyMongoError as e:
            logger.error(f"MongoDB error getting service history: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting service history: {e}")
            return []

    def get_host_history(
        self,
        host_id: str,
        limit: int = 100,
        hours: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Get monitoring history for all services on a host

        Args:
            host_id: Host identifier
            limit: Maximum number of records
            hours: Only get history from last N hours

        Returns:
            List of history documents
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return []

            query_filter = {"host_id": host_id}

            # Add time filter if specified
            if hours:
                since = datetime.utcnow() - timedelta(hours=hours)
                query_filter["timestamp"] = {"$gte": since}

            cursor = collection.find(query_filter).sort("timestamp", DESCENDING).limit(limit)
            history = list(cursor)

            # Convert ObjectId to string
            for record in history:
                if '_id' in record:
                    record['_id'] = str(record['_id'])

            return history

        except PyMongoError as e:
            logger.error(f"MongoDB error getting host history: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting host history: {e}")
            return []

    def get_recent_failures(self, hours: int = 24, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Get recent failed checks

        Args:
            hours: Look back N hours
            limit: Maximum number of records

        Returns:
            List of failed check documents
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return []

            since = datetime.utcnow() - timedelta(hours=hours)

            query_filter = {
                "status": {"$ne": "running"},
                "timestamp": {"$gte": since}
            }

            cursor = collection.find(query_filter).sort("timestamp", DESCENDING).limit(limit)
            failures = list(cursor)

            # Convert ObjectId to string
            for record in failures:
                if '_id' in record:
                    record['_id'] = str(record['_id'])

            return failures

        except PyMongoError as e:
            logger.error(f"MongoDB error getting recent failures: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting recent failures: {e}")
            return []

    def get_service_uptime(self, service_id: str, days: int = 30) -> float:
        """
        Calculate service uptime percentage

        Args:
            service_id: Service identifier
            days: Number of days to calculate

        Returns:
            Uptime percentage (0-100)
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return 0.0

            since = datetime.utcnow() - timedelta(days=days)

            # Total checks
            total_checks = collection.count_documents({
                "service_id": service_id,
                "timestamp": {"$gte": since}
            })

            if total_checks == 0:
                return 0.0

            # Successful checks
            successful_checks = collection.count_documents({
                "service_id": service_id,
                "timestamp": {"$gte": since},
                "status": "running"
            })

            uptime = round((successful_checks / total_checks) * 100, 2)
            return uptime

        except PyMongoError as e:
            logger.error(f"MongoDB error calculating uptime: {e}")
            return 0.0
        except Exception as e:
            logger.error(f"Unexpected error calculating uptime: {e}")
            return 0.0

    def get_check_statistics(
        self,
        service_id: Optional[str] = None,
        host_id: Optional[str] = None,
        hours: int = 24
    ) -> Dict[str, Any]:
        """
        Get statistics for monitoring checks

        Args:
            service_id: Filter by service (optional)
            host_id: Filter by host (optional)
            hours: Look back N hours

        Returns:
            Statistics dictionary
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return {}

            since = datetime.utcnow() - timedelta(hours=hours)

            # Build match filter
            match_filter = {"timestamp": {"$gte": since}}
            if service_id:
                match_filter["service_id"] = service_id
            if host_id:
                match_filter["host_id"] = host_id

            # Aggregation pipeline
            pipeline = [
                {"$match": match_filter},
                {
                    "$group": {
                        "_id": "$status",
                        "count": {"$sum": 1},
                        "avg_response_time": {"$avg": "$response_time_ms"}
                    }
                }
            ]

            results = list(collection.aggregate(pipeline))

            # Format results
            total_checks = sum(r["count"] for r in results)
            by_status = {r["_id"]: r["count"] for r in results}

            stats = {
                "period_hours": hours,
                "total_checks": total_checks,
                "by_status": by_status,
                "success_rate": round(
                    (by_status.get("running", 0) / total_checks * 100) if total_checks > 0 else 0,
                    2
                )
            }

            # Add average response times
            for r in results:
                if r.get("avg_response_time"):
                    stats[f"avg_response_time_{r['_id']}"] = round(r["avg_response_time"], 2)

            return stats

        except PyMongoError as e:
            logger.error(f"MongoDB error getting check statistics: {e}")
            return {}
        except Exception as e:
            logger.error(f"Unexpected error getting check statistics: {e}")
            return {}

    def delete_old_history(self, days: int = 30) -> int:
        """
        Delete monitoring history older than specified days
        (Note: TTL index handles this automatically, but this method
        provides manual cleanup if needed)

        Args:
            days: Delete records older than N days

        Returns:
            Number of deleted records
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return 0

            cutoff_date = datetime.utcnow() - timedelta(days=days)

            result = collection.delete_many({"timestamp": {"$lt": cutoff_date}})
            deleted_count = result.deleted_count

            logger.info(f"Deleted {deleted_count} old monitoring records older than {days} days")
            return deleted_count

        except PyMongoError as e:
            logger.error(f"MongoDB error deleting old history: {e}")
            return 0
        except Exception as e:
            logger.error(f"Unexpected error deleting old history: {e}")
            return 0

    def get_recovery_attempts(
        self,
        service_id: Optional[str] = None,
        hours: int = 24
    ) -> List[Dict[str, Any]]:
        """
        Get recovery attempts for a service or all services

        Args:
            service_id: Service identifier (optional)
            hours: Look back N hours

        Returns:
            List of recovery attempt documents
        """
        try:
            collection = self.monitoring_history_collection
            if collection is None:
                logger.error("Monitoring history collection not available")
                return []

            since = datetime.utcnow() - timedelta(hours=hours)

            query_filter = {
                "recovery_attempted": True,
                "timestamp": {"$gte": since}
            }

            if service_id:
                query_filter["service_id"] = service_id

            cursor = collection.find(query_filter).sort("timestamp", DESCENDING)
            attempts = list(cursor)

            # Convert ObjectId to string
            for record in attempts:
                if '_id' in record:
                    record['_id'] = str(record['_id'])

            return attempts

        except PyMongoError as e:
            logger.error(f"MongoDB error getting recovery attempts: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting recovery attempts: {e}")
            return []


# Global operations instance
monitoring_operations = MonitoringOperations()
