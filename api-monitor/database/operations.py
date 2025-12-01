import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Union
from pymongo.errors import PyMongoError
from .connection import mongo_connection
from .models import LogEntry, EventEntry, LogLevel, ServiceStatus

logger = logging.getLogger(__name__)

# Guatemala timezone offset (GMT-6)
GUATEMALA_UTC_OFFSET = timedelta(hours=-6)


def convert_utc_to_guatemala(utc_dt):
    """
    Convert UTC datetime to Guatemala time (GMT-6)

    Args:
        utc_dt: datetime object in UTC

    Returns:
        datetime object in Guatemala time
    """
    if utc_dt is None:
        return None

    if isinstance(utc_dt, datetime):
        return utc_dt + GUATEMALA_UTC_OFFSET

    return utc_dt


def convert_timestamps_in_results(results):
    """
    Convert timestamp fields from UTC to Guatemala time in result documents

    Args:
        results: List of dictionaries containing log entries

    Returns:
        List with converted timestamps
    """
    for result in results:
        if 'timestamp' in result and isinstance(result['timestamp'], datetime):
            result['timestamp'] = convert_utc_to_guatemala(result['timestamp'])

        # Also convert other datetime fields if present
        if 'created_at' in result and isinstance(result['created_at'], datetime):
            result['created_at'] = convert_utc_to_guatemala(result['created_at'])

        if 'updated_at' in result and isinstance(result['updated_at'], datetime):
            result['updated_at'] = convert_utc_to_guatemala(result['updated_at'])

    return results


class LogOperations:
    """MongoDB operations for logging system"""

    def __init__(self):
        self.connection = mongo_connection

    def save_log(self, log_entry: LogEntry) -> bool:
        """Save a single log entry to MongoDB"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                logger.error("Logs collection not available")
                return False

            document = log_entry.to_document()
            result = collection.insert_one(document)

            if result.inserted_id:
                logger.debug(f"Log entry saved with ID: {result.inserted_id}")
                return True
            else:
                logger.error("Failed to save log entry")
                return False

        except PyMongoError as e:
            logger.error(f"MongoDB error saving log: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error saving log: {e}")
            return False

    def save_logs_batch(self, log_entries: List[LogEntry]) -> int:
        """Save multiple log entries in batch"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                logger.error("Logs collection not available")
                return 0

            documents = [entry.to_document() for entry in log_entries]
            result = collection.insert_many(documents)

            saved_count = len(result.inserted_ids)
            logger.info(f"Batch saved {saved_count}/{len(log_entries)} log entries")
            return saved_count

        except PyMongoError as e:
            logger.error(f"MongoDB error saving batch logs: {e}")
            return 0
        except Exception as e:
            logger.error(f"Unexpected error saving batch logs: {e}")
            return 0

    def save_event(self, event_entry: EventEntry) -> bool:
        """Save an event entry to MongoDB"""
        try:
            collection = self.connection.events_collection
            if collection is None:
                logger.error("Events collection not available")
                return False

            document = event_entry.to_document()
            result = collection.insert_one(document)

            if result.inserted_id:
                logger.debug(f"Event entry saved with ID: {result.inserted_id}")
                return True
            else:
                logger.error("Failed to save event entry")
                return False

        except PyMongoError as e:
            logger.error(f"MongoDB error saving event: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error saving event: {e}")
            return False

    def get_logs(
        self,
        service_name: Optional[str] = None,
        log_level: Optional[LogLevel] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        host: Optional[str] = None,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """Query logs with various filters. Timestamps are returned in Guatemala time (GMT-6)"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                logger.error("Logs collection not available")
                return []

            # Build query filter
            query_filter = {}

            if service_name:
                query_filter['service_name'] = service_name

            if log_level:
                query_filter['log_level'] = log_level.value

            if host:
                query_filter['host'] = host

            if start_time or end_time:
                time_filter = {}
                if start_time:
                    time_filter['$gte'] = start_time
                if end_time:
                    time_filter['$lte'] = end_time
                query_filter['timestamp'] = time_filter

            # Execute query
            cursor = collection.find(query_filter).sort('timestamp', -1).skip(skip).limit(limit)
            results = list(cursor)

            # Convert timestamps from UTC to Guatemala time
            results = convert_timestamps_in_results(results)

            logger.debug("Retrieved {} log entries".format(len(results)))
            return results

        except PyMongoError as e:
            logger.error("MongoDB error querying logs: {}".format(e))
            return []
        except Exception as e:
            logger.error("Unexpected error querying logs: {}".format(e))
            return []

    def get_recent_logs(self, service_name: str, hours: int = 24, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent logs for a specific service"""
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=hours)

        return self.get_logs(
            service_name=service_name,
            start_time=start_time,
            end_time=end_time,
            limit=limit
        )

    def get_error_logs(self, hours: int = 24, limit: int = 50) -> List[Dict[str, Any]]:
        """Get recent error and warning logs"""
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(hours=hours)

        try:
            collection = self.connection.logs_collection
            if collection is None:
                return []

            query_filter = {
                'log_level': {'$in': [LogLevel.ERROR.value, LogLevel.WARNING.value, LogLevel.CRITICAL.value]},
                'timestamp': {'$gte': start_time, '$lte': end_time}
            }

            cursor = collection.find(query_filter).sort('timestamp', -1).limit(limit)
            return list(cursor)

        except PyMongoError as e:
            logger.error(f"MongoDB error querying error logs: {e}")
            return []

    def get_service_statistics(self, service_name: str, hours: int = 24) -> Dict[str, Any]:
        """Get statistics for a specific service"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                return {}

            end_time = datetime.utcnow()
            start_time = end_time - timedelta(hours=hours)

            pipeline = [
                {
                    '$match': {
                        'service_name': service_name,
                        'timestamp': {'$gte': start_time, '$lte': end_time}
                    }
                },
                {
                    '$group': {
                        '_id': '$log_level',
                        'count': {'$sum': 1},
                        'latest': {'$max': '$timestamp'}
                    }
                }
            ]

            results = list(collection.aggregate(pipeline))

            # Format statistics
            stats = {
                'service_name': service_name,
                'period_hours': hours,
                'total_logs': sum(r['count'] for r in results),
                'by_level': {r['_id']: r['count'] for r in results},
                'latest_activity': max((r['latest'] for r in results), default=None)
            }

            return stats

        except PyMongoError as e:
            logger.error(f"MongoDB error getting service statistics: {e}")
            return {}

    def delete_old_logs(self, days_to_keep: int = 30) -> int:
        """Delete old log entries to manage storage"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                return 0

            cutoff_date = datetime.utcnow() - timedelta(days=days_to_keep)

            result = collection.delete_many({'timestamp': {'$lt': cutoff_date}})
            deleted_count = result.deleted_count

            logger.info(f"Deleted {deleted_count} old log entries older than {days_to_keep} days")
            return deleted_count

        except PyMongoError as e:
            logger.error(f"MongoDB error deleting old logs: {e}")
            return 0

    def get_unsent_logs(
        self,
        service_name: Optional[str] = None,
        log_level: Optional[LogLevel] = None,
        limit: int = 100
    ) -> List[Dict[str, Any]]:
        """Get logs that haven't been sent to user yet. Timestamps are returned in Guatemala time (GMT-6)"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                logger.error("Logs collection not available")
                return []

            # Build query filter for unsent logs
            query_filter = {'sent_to_user': False}

            if service_name:
                query_filter['service_name'] = service_name

            if log_level:
                query_filter['log_level'] = log_level.value

            # Execute query
            cursor = collection.find(query_filter).sort('timestamp', -1).limit(limit)
            results = list(cursor)

            # Convert timestamps from UTC to Guatemala time
            results = convert_timestamps_in_results(results)

            logger.debug("Retrieved {} unsent log entries".format(len(results)))
            return results

        except PyMongoError as e:
            logger.error("MongoDB error querying unsent logs: {}".format(e))
            return []
        except Exception as e:
            logger.error("Unexpected error querying unsent logs: {}".format(e))
            return []

    def mark_logs_as_sent(self, log_ids: List[str]) -> int:
        """Mark logs as sent to user"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                logger.error("Logs collection not available")
                return 0

            from bson import ObjectId

            # Convert string IDs to ObjectId
            object_ids = []
            for log_id in log_ids:
                try:
                    object_ids.append(ObjectId(log_id))
                except Exception as e:
                    logger.warning(f"Invalid ObjectId: {log_id} - {e}")

            if not object_ids:
                return 0

            # Update logs to mark as sent
            result = collection.update_many(
                {'_id': {'$in': object_ids}},
                {'$set': {'sent_to_user': True}}
            )

            updated_count = result.modified_count
            logger.debug(f"Marked {updated_count} logs as sent")
            return updated_count

        except PyMongoError as e:
            logger.error(f"MongoDB error marking logs as sent: {e}")
            return 0
        except Exception as e:
            logger.error(f"Unexpected error marking logs as sent: {e}")
            return 0

    def get_service_summary(self) -> Dict[str, Any]:
        """Get summary of all services and their status"""
        try:
            collection = self.connection.logs_collection
            if collection is None:
                return {}

            pipeline = [
                {
                    '$group': {
                        '_id': '$service_name',
                        'total_logs': {'$sum': 1},
                        'unsent_logs': {
                            '$sum': {'$cond': [{'$eq': ['$sent_to_user', False]}, 1, 0]}
                        },
                        'latest_timestamp': {'$max': '$timestamp'},
                        'latest_status': {'$last': '$status'},
                        'latest_level': {'$last': '$log_level'},
                        'service_type': {'$last': '$service_type'},
                        'host': {'$last': '$host'}
                    }
                },
                {
                    '$sort': {'latest_timestamp': -1}
                }
            ]

            results = list(collection.aggregate(pipeline))

            summary = {
                'total_services': len(results),
                'services': results,
                'last_updated': datetime.utcnow().isoformat()
            }

            return summary

        except PyMongoError as e:
            logger.error(f"MongoDB error getting service summary: {e}")
            return {}

    def import_from_file(self, file_path: str, host: str = "localhost") -> int:
        """Import logs from existing log file"""
        imported_count = 0
        batch_size = 100
        batch = []

        try:
            with open(file_path, 'r') as file:
                for line in file:
                    log_entry = LogEntry.from_monitor_log(line.strip(), host)
                    if log_entry:
                        batch.append(log_entry)

                        if len(batch) >= batch_size:
                            imported_count += self.save_logs_batch(batch)
                            batch = []

                # Save remaining entries
                if batch:
                    imported_count += self.save_logs_batch(batch)

            logger.info(f"Imported {imported_count} log entries from {file_path}")
            return imported_count

        except FileNotFoundError:
            logger.error(f"Log file not found: {file_path}")
            return 0
        except Exception as e:
            logger.error(f"Error importing from file {file_path}: {e}")
            return 0

# Global operations instance
log_operations = LogOperations()