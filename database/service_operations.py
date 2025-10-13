"""
MongoDB operations for Service management
"""

import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from pymongo.errors import PyMongoError, DuplicateKeyError
from .connection import mongo_connection
from .monitoring_models import Service, ServiceStatus

logger = logging.getLogger(__name__)


class ServiceOperations:
    """MongoDB operations for service management"""

    def __init__(self):
        self.connection = mongo_connection

    @property
    def services_collection(self):
        """Get services collection"""
        if self.connection.database is None:
            return None
        return self.connection.database['services']

    def create_service(self, service: Service) -> Optional[str]:
        """
        Create a new service

        Args:
            service: Service object to create

        Returns:
            service_id if successful, None otherwise
        """
        try:
            collection = self.services_collection
            if collection is None:
                logger.error("Services collection not available")
                return None

            document = service.to_document()
            result = collection.insert_one(document)

            if result.inserted_id:
                logger.info(f"Service created: {service.service_id}")
                return service.service_id
            else:
                logger.error("Failed to create service")
                return None

        except DuplicateKeyError:
            logger.error(f"Service with ID '{service.service_id}' already exists")
            return None
        except PyMongoError as e:
            logger.error(f"MongoDB error creating service: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error creating service: {e}")
            return None

    def get_service(self, service_id: str) -> Optional[Dict[str, Any]]:
        """
        Get service by service_id

        Args:
            service_id: Service identifier

        Returns:
            Service document or None
        """
        try:
            collection = self.services_collection
            if collection is None:
                logger.error("Services collection not available")
                return None

            service_doc = collection.find_one({"service_id": service_id})

            if service_doc and '_id' in service_doc:
                service_doc['_id'] = str(service_doc['_id'])

            return service_doc

        except PyMongoError as e:
            logger.error(f"MongoDB error getting service: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error getting service: {e}")
            return None

    def get_all_services(
        self,
        host_id: Optional[str] = None,
        service_type: Optional[str] = None,
        environment: Optional[str] = None,
        region: Optional[str] = None,
        status: Optional[str] = None,
        enabled_only: bool = False,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get all services with optional filters

        Args:
            host_id: Filter by host
            service_type: Filter by service type
            environment: Filter by environment
            region: Filter by region
            status: Filter by status
            enabled_only: If True, only return enabled services
            limit: Maximum number of results
            skip: Number of results to skip

        Returns:
            List of service documents
        """
        try:
            collection = self.services_collection
            if collection is None:
                logger.error("Services collection not available")
                return []

            # Build query filter
            query_filter = {}
            if host_id:
                query_filter['host_id'] = host_id
            if service_type:
                query_filter['service_type'] = service_type
            if environment:
                query_filter['environment'] = environment
            if region:
                query_filter['region'] = region
            if status:
                query_filter['current_status'] = status
            if enabled_only:
                query_filter['monitoring.enabled'] = True

            # Execute query
            cursor = collection.find(query_filter).sort('created_at', -1).skip(skip).limit(limit)
            services = list(cursor)

            # Convert ObjectId to string
            for service in services:
                if '_id' in service:
                    service['_id'] = str(service['_id'])

            logger.debug(f"Retrieved {len(services)} services")
            return services

        except PyMongoError as e:
            logger.error(f"MongoDB error getting services: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting services: {e}")
            return []

    def get_services_by_host(self, host_id: str) -> List[Dict[str, Any]]:
        """Get all services for a specific host"""
        return self.get_all_services(host_id=host_id)

    def get_services_by_type(self, service_type: str) -> List[Dict[str, Any]]:
        """Get all services of a specific type"""
        return self.get_all_services(service_type=service_type)

    def get_enabled_services(self) -> List[Dict[str, Any]]:
        """Get all services with monitoring enabled"""
        return self.get_all_services(enabled_only=True, limit=1000)

    def update_service(self, service_id: str, update_data: Dict[str, Any]) -> bool:
        """
        Update service information

        Args:
            service_id: Service identifier
            update_data: Fields to update

        Returns:
            True if successful, False otherwise
        """
        try:
            collection = self.services_collection
            if collection is None:
                logger.error("Services collection not available")
                return False

            # Add updated_at timestamp
            update_data['updated_at'] = datetime.utcnow()

            result = collection.update_one(
                {"service_id": service_id},
                {"$set": update_data}
            )

            if result.modified_count > 0:
                logger.info(f"Service updated: {service_id}")
                return True
            else:
                logger.warning(f"No changes made to service: {service_id}")
                return False

        except PyMongoError as e:
            logger.error(f"MongoDB error updating service: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error updating service: {e}")
            return False

    def update_service_status(
        self,
        service_id: str,
        status: str,
        response_time_ms: Optional[int] = None,
        error: Optional[str] = None
    ) -> bool:
        """
        Update service status after a check

        Args:
            service_id: Service identifier
            status: New status
            response_time_ms: Response time in milliseconds
            error: Error message if check failed

        Returns:
            True if successful, False otherwise
        """
        try:
            collection = self.services_collection
            if collection is None:
                logger.error("Services collection not available")
                return False

            # Get current service to check if status changed
            service = self.get_service(service_id)
            if not service:
                logger.warning(f"Service not found: {service_id}")
                return False

            update_data = {
                "current_status": status,
                "last_check": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }

            # Track status changes
            if service.get("current_status") != status:
                update_data["last_status_change"] = datetime.utcnow()

                # Reset or increment failure counter
                if status == "running":
                    update_data["consecutive_failures"] = 0
                else:
                    update_data["consecutive_failures"] = service.get("consecutive_failures", 0) + 1

            result = collection.update_one(
                {"service_id": service_id},
                {"$set": update_data}
            )

            return result.modified_count > 0

        except PyMongoError as e:
            logger.error(f"MongoDB error updating service status: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error updating service status: {e}")
            return False

    def delete_service(self, service_id: str) -> bool:
        """
        Delete a service

        Args:
            service_id: Service identifier

        Returns:
            True if successful, False otherwise
        """
        try:
            collection = self.services_collection
            if collection is None:
                logger.error("Services collection not available")
                return False

            result = collection.delete_one({"service_id": service_id})

            if result.deleted_count > 0:
                logger.info(f"Service deleted: {service_id}")
                return True
            else:
                logger.warning(f"Service not found: {service_id}")
                return False

        except PyMongoError as e:
            logger.error(f"MongoDB error deleting service: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error deleting service: {e}")
            return False

    def get_service_count(
        self,
        host_id: Optional[str] = None,
        service_type: Optional[str] = None,
        environment: Optional[str] = None,
        status: Optional[str] = None
    ) -> int:
        """
        Get count of services with optional filters

        Args:
            host_id: Filter by host
            service_type: Filter by service type
            environment: Filter by environment
            status: Filter by status

        Returns:
            Count of services
        """
        try:
            collection = self.services_collection
            if collection is None:
                return 0

            # Build query filter
            query_filter = {}
            if host_id:
                query_filter['host_id'] = host_id
            if service_type:
                query_filter['service_type'] = service_type
            if environment:
                query_filter['environment'] = environment
            if status:
                query_filter['current_status'] = status

            count = collection.count_documents(query_filter)
            return count

        except PyMongoError as e:
            logger.error(f"MongoDB error counting services: {e}")
            return 0
        except Exception as e:
            logger.error(f"Unexpected error counting services: {e}")
            return 0

    def get_services_needing_attention(self) -> Dict[str, List[Dict[str, Any]]]:
        """
        Get services that need attention (down, high failures, stale checks)

        Returns:
            Dictionary with categorized services
        """
        try:
            collection = self.services_collection
            if collection is None:
                return {}

            # Down services (stopped or error status)
            down_services = list(collection.find({
                "current_status": {"$in": ["stopped", "error"]}
            }))

            # High failure rate (3+ consecutive failures)
            high_failure_services = list(collection.find({
                "consecutive_failures": {"$gte": 3}
            }))

            # Stale checks (not checked in last 10 minutes)
            stale_threshold = datetime.utcnow() - timedelta(minutes=10)
            stale_services = list(collection.find({
                "last_check": {"$lt": stale_threshold},
                "monitoring.enabled": True
            }))

            # Convert ObjectId to string
            for service_list in [down_services, high_failure_services, stale_services]:
                for service in service_list:
                    if '_id' in service:
                        service['_id'] = str(service['_id'])

            return {
                "down_services": down_services,
                "high_failure_rate": high_failure_services,
                "stale_checks": stale_services
            }

        except PyMongoError as e:
            logger.error(f"MongoDB error getting services needing attention: {e}")
            return {}
        except Exception as e:
            logger.error(f"Unexpected error getting services needing attention: {e}")
            return {}

    def get_dashboard_summary(self) -> Dict[str, Any]:
        """
        Get overall service monitoring summary

        Returns:
            Summary statistics
        """
        try:
            collection = self.services_collection
            if collection is None:
                return {}

            total_services = collection.count_documents({})
            running_services = collection.count_documents({"current_status": "running"})
            stopped_services = collection.count_documents({"current_status": "stopped"})
            error_services = collection.count_documents({"current_status": "error"})
            unknown_services = collection.count_documents({"current_status": "unknown"})

            # Group by environment
            by_environment = list(collection.aggregate([
                {"$group": {"_id": "$environment", "count": {"$sum": 1}}}
            ]))

            # Group by region
            by_region = list(collection.aggregate([
                {"$group": {"_id": "$region", "count": {"$sum": 1}}}
            ]))

            # Group by service type
            by_service_type = list(collection.aggregate([
                {"$group": {"_id": "$service_type", "count": {"$sum": 1}}}
            ]))

            return {
                "total_services": total_services,
                "running_services": running_services,
                "stopped_services": stopped_services,
                "error_services": error_services,
                "unknown_services": unknown_services,
                "by_environment": by_environment,
                "by_region": by_region,
                "by_service_type": by_service_type
            }

        except PyMongoError as e:
            logger.error(f"MongoDB error getting dashboard summary: {e}")
            return {}
        except Exception as e:
            logger.error(f"Unexpected error getting dashboard summary: {e}")
            return {}

    def service_exists(self, service_id: str) -> bool:
        """
        Check if a service exists

        Args:
            service_id: Service identifier

        Returns:
            True if service exists, False otherwise
        """
        try:
            collection = self.services_collection
            if collection is None:
                return False

            count = collection.count_documents({"service_id": service_id}, limit=1)
            return count > 0

        except PyMongoError as e:
            logger.error(f"MongoDB error checking service existence: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error checking service existence: {e}")
            return False


# Global operations instance
service_operations = ServiceOperations()
