"""
MongoDB operations for Host management
"""

import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from pymongo.errors import PyMongoError, DuplicateKeyError
from .connection import mongo_connection
from .monitoring_models import Host, HostStatus

logger = logging.getLogger(__name__)


class HostOperations:
    """MongoDB operations for host management"""

    def __init__(self):
        self.connection = mongo_connection

    @property
    def hosts_collection(self):
        """Get hosts collection"""
        if self.connection.database is None:
            return None
        return self.connection.database['hosts']

    def create_host(self, host: Host) -> Optional[str]:
        """
        Create a new host

        Args:
            host: Host object to create

        Returns:
            host_id if successful, None otherwise
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                logger.error("Hosts collection not available")
                return None

            document = host.to_document()
            result = collection.insert_one(document)

            if result.inserted_id:
                logger.info(f"Host created: {host.host_id}")
                return host.host_id
            else:
                logger.error("Failed to create host")
                return None

        except DuplicateKeyError:
            logger.error(f"Host with ID '{host.host_id}' already exists")
            return None
        except PyMongoError as e:
            logger.error(f"MongoDB error creating host: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error creating host: {e}")
            return None

    def get_host(self, host_id: str) -> Optional[Dict[str, Any]]:
        """
        Get host by host_id

        Args:
            host_id: Host identifier

        Returns:
            Host document or None
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                logger.error("Hosts collection not available")
                return None

            host_doc = collection.find_one({"host_id": host_id})

            if host_doc and '_id' in host_doc:
                host_doc['_id'] = str(host_doc['_id'])

            return host_doc

        except PyMongoError as e:
            logger.error(f"MongoDB error getting host: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error getting host: {e}")
            return None

    def get_all_hosts(
        self,
        environment: Optional[str] = None,
        region: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100,
        skip: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get all hosts with optional filters

        Args:
            environment: Filter by environment
            region: Filter by region
            status: Filter by status
            limit: Maximum number of results
            skip: Number of results to skip

        Returns:
            List of host documents
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                logger.error("Hosts collection not available")
                return []

            # Build query filter
            query_filter = {}
            if environment:
                query_filter['environment'] = environment
            if region:
                query_filter['region'] = region
            if status:
                query_filter['status'] = status

            # Execute query
            cursor = collection.find(query_filter).sort('created_at', -1).skip(skip).limit(limit)
            hosts = list(cursor)

            # Convert ObjectId to string
            for host in hosts:
                if '_id' in host:
                    host['_id'] = str(host['_id'])

            logger.debug(f"Retrieved {len(hosts)} hosts")
            return hosts

        except PyMongoError as e:
            logger.error(f"MongoDB error getting hosts: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting hosts: {e}")
            return []

    def get_hosts_by_environment(self, environment: str) -> List[Dict[str, Any]]:
        """Get all hosts in a specific environment"""
        return self.get_all_hosts(environment=environment)

    def get_hosts_by_region(self, region: str) -> List[Dict[str, Any]]:
        """Get all hosts in a specific region"""
        return self.get_all_hosts(region=region)

    def update_host(self, host_id: str, update_data: Dict[str, Any]) -> bool:
        """
        Update host information

        Args:
            host_id: Host identifier
            update_data: Fields to update

        Returns:
            True if successful, False otherwise
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                logger.error("Hosts collection not available")
                return False

            # Add updated_at timestamp
            update_data['updated_at'] = datetime.utcnow()

            result = collection.update_one(
                {"host_id": host_id},
                {"$set": update_data}
            )

            if result.modified_count > 0:
                logger.info(f"Host updated: {host_id}")
                return True
            else:
                logger.warning(f"No changes made to host: {host_id}")
                return False

        except PyMongoError as e:
            logger.error(f"MongoDB error updating host: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error updating host: {e}")
            return False

    def delete_host(self, host_id: str, delete_services: bool = True) -> bool:
        """
        Delete a host

        Args:
            host_id: Host identifier
            delete_services: If True, also delete all services for this host

        Returns:
            True if successful, False otherwise
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                logger.error("Hosts collection not available")
                return False

            # Delete associated services if requested
            if delete_services:
                services_collection = self.connection.database['services']
                if services_collection is not None:
                    services_result = services_collection.delete_many({"host_id": host_id})
                    logger.info(f"Deleted {services_result.deleted_count} services for host {host_id}")

            # Delete host
            result = collection.delete_one({"host_id": host_id})

            if result.deleted_count > 0:
                logger.info(f"Host deleted: {host_id}")
                return True
            else:
                logger.warning(f"Host not found: {host_id}")
                return False

        except PyMongoError as e:
            logger.error(f"MongoDB error deleting host: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error deleting host: {e}")
            return False

    def update_last_seen(self, host_id: str) -> bool:
        """
        Update the last_seen timestamp for a host

        Args:
            host_id: Host identifier

        Returns:
            True if successful, False otherwise
        """
        return self.update_host(host_id, {"last_seen": datetime.utcnow()})

    def get_host_count(
        self,
        environment: Optional[str] = None,
        region: Optional[str] = None,
        status: Optional[str] = None
    ) -> int:
        """
        Get count of hosts with optional filters

        Args:
            environment: Filter by environment
            region: Filter by region
            status: Filter by status

        Returns:
            Count of hosts
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                return 0

            # Build query filter
            query_filter = {}
            if environment:
                query_filter['environment'] = environment
            if region:
                query_filter['region'] = region
            if status:
                query_filter['status'] = status

            count = collection.count_documents(query_filter)
            return count

        except PyMongoError as e:
            logger.error(f"MongoDB error counting hosts: {e}")
            return 0
        except Exception as e:
            logger.error(f"Unexpected error counting hosts: {e}")
            return 0

    def get_environments(self) -> List[str]:
        """
        Get list of all unique environments

        Returns:
            List of environment names
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                return []

            environments = collection.distinct("environment")
            return sorted(environments)

        except PyMongoError as e:
            logger.error(f"MongoDB error getting environments: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting environments: {e}")
            return []

    def get_regions(self) -> List[str]:
        """
        Get list of all unique regions

        Returns:
            List of region names
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                return []

            regions = collection.distinct("region")
            return sorted(regions)

        except PyMongoError as e:
            logger.error(f"MongoDB error getting regions: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting regions: {e}")
            return []

    def host_exists(self, host_id: str) -> bool:
        """
        Check if a host exists

        Args:
            host_id: Host identifier

        Returns:
            True if host exists, False otherwise
        """
        try:
            collection = self.hosts_collection
            if collection is None:
                return False

            count = collection.count_documents({"host_id": host_id}, limit=1)
            return count > 0

        except PyMongoError as e:
            logger.error(f"MongoDB error checking host existence: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error checking host existence: {e}")
            return False


# Global operations instance
host_operations = HostOperations()
