# MongoDB Schema Design - Service Monitoring System

## Table of Contents
1. [Overview](#overview)
2. [Collection Structure](#collection-structure)
3. [Indexes Strategy](#indexes-strategy)
4. [Python Integration](#python-integration)
5. [Common Queries](#common-queries)
6. [Migration Script](#migration-script)
7. [Best Practices](#best-practices)

---

## Overview

This document describes the MongoDB schema design for a distributed service monitoring system using **Option B: Referenced Collections** approach.

### Design Goals
- Support 10-100 hosts initially with incremental growth
- 5-10 services per host
- Track environments (dev/staging/prod)
- Support geographical regions/datacenters
- Store monitoring history and metrics
- Enable flexible querying by host, service type, environment, region, and status

### Architecture
- **3 Main Collections**: hosts, services, monitoring_history
- **1 Optional Collection**: environments (reference data)
- **Referenced approach**: Services reference hosts via `host_id`
- **Denormalization**: Critical fields (environment, region) duplicated in services for query performance

---

## Collection Structure

### 1. `hosts` Collection

Stores host/server information and SSH configuration.

```javascript
{
  "_id": ObjectId("..."),
  "host_id": "host_jeju_mysql_001",  // Human-readable unique ID
  "hostname": "jeju-mysql",
  "ip_address": "10.1.11.81",
  "environment": "production",  // dev, staging, production
  "region": "asia-pacific",     // or datacenter name
  "location": {
    "datacenter": "Seoul-DC1",
    "rack": "A-12",
    "zone": "zone-1"
  },
  "ssh_config": {
    "user": "ubuntu",
    "port": 22,
    "key_path": "/path/to/key",  // optional
    "use_sudo": true
  },
  "metadata": {
    "os": "Ubuntu 22.04",
    "purpose": "Database Server",
    "tags": ["mysql", "critical", "backup-enabled"]
  },
  "status": "active",  // active, maintenance, decommissioned
  "created_at": ISODate("2025-10-12T00:00:00Z"),
  "updated_at": ISODate("2025-10-12T00:00:00Z"),
  "last_seen": ISODate("2025-10-12T12:00:00Z")
}
```

**Fields Description:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `host_id` | String | Yes | Unique human-readable identifier |
| `hostname` | String | Yes | Server hostname |
| `ip_address` | String | Yes | IPv4/IPv6 address |
| `environment` | String | Yes | Environment name (dev/staging/production) |
| `region` | String | Yes | Geographic region or datacenter |
| `location` | Object | No | Detailed physical location |
| `ssh_config` | Object | Yes | SSH connection configuration |
| `metadata` | Object | No | Additional information and tags |
| `status` | String | Yes | Host operational status |
| `created_at` | Date | Yes | Creation timestamp |
| `updated_at` | Date | Yes | Last update timestamp |
| `last_seen` | Date | Yes | Last successful connection |

---

### 2. `services` Collection

Stores service configurations and monitoring settings for each host.

```javascript
{
  "_id": ObjectId("..."),
  "service_id": "svc_jeju_mysql_001",
  "host_id": "host_jeju_mysql_001",  // Reference to hosts collection
  
  // Service details
  "service_name": "mysql.service",
  "service_type": "mysql",  // mysql, postgresql, nginx, apache, etc.
  "display_name": "MySQL Database Server",
  "description": "Primary MySQL instance for application data",
  
  // Monitoring config
  "monitoring": {
    "method": "ssh",  // ssh, http, tcp, database, custom
    "enabled": true,
    "interval_sec": 45,
    "timeout_sec": 30,
    "retry_attempts": 3,
    "retry_delay_sec": 5
  },
  
  // Recovery config
  "recovery": {
    "recover_on_down": true,
    "recover_action": "restart",  // restart, reload, stop, start, custom_script
    "custom_script": null,
    "max_recovery_attempts": 3,
    "recovery_cooldown_sec": 300,
    "notify_before_recovery": true
  },
  
  // Alerting (optional for future)
  "alerting": {
    "enabled": true,
    "channels": ["slack", "email", "pagerduty"],
    "severity": "high",  // low, medium, high, critical
    "escalation_policy": "db-team",
    "mute_until": null  // ISODate or null
  },
  
  // Health check (optional)
  "health_check": {
    "enabled": false,
    "endpoint": null,
    "expected_response": null,
    "custom_check": null
  },
  
  // Status
  "current_status": "running",  // running, stopped, unknown, error, warning
  "last_check": ISODate("2025-10-12T12:00:00Z"),
  "last_status_change": ISODate("2025-10-12T10:00:00Z"),
  "uptime_percentage": 99.95,  // Last 30 days
  "consecutive_failures": 0,
  
  // Metadata (denormalized for performance)
  "environment": "production",  // Duplicated from host
  "region": "asia-pacific",     // Duplicated from host
  "tags": ["database", "critical", "replicated"],
  "dependencies": ["svc_jeju_redis_001"],  // Service IDs this depends on
  
  "created_at": ISODate("2025-10-12T00:00:00Z"),
  "updated_at": ISODate("2025-10-12T00:00:00Z")
}
```

**Fields Description:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `service_id` | String | Yes | Unique service identifier |
| `host_id` | String | Yes | Reference to host |
| `service_name` | String | Yes | Systemctl service name |
| `service_type` | String | Yes | Type/category of service |
| `display_name` | String | No | Human-friendly name |
| `monitoring` | Object | Yes | Monitoring configuration |
| `recovery` | Object | Yes | Auto-recovery settings |
| `alerting` | Object | No | Alert configuration |
| `current_status` | String | Yes | Current service status |
| `environment` | String | Yes | Environment (denormalized) |
| `region` | String | Yes | Region (denormalized) |

---

### 3. `monitoring_history` Collection

Stores historical monitoring data, metrics, and check results.

```javascript
{
  "_id": ObjectId("..."),
  "service_id": "svc_jeju_mysql_001",
  "host_id": "host_jeju_mysql_001",  // Denormalized for easier queries
  
  "timestamp": ISODate("2025-10-12T12:00:00Z"),
  "check_type": "status_check",  // status_check, health_check, performance
  
  "status": "running",
  "status_code": 0,  // 0 = success, >0 = error
  "response_time_ms": 145,
  
  "metrics": {
    "cpu_usage": 45.2,
    "memory_usage": 62.8,
    "disk_usage": 78.5,
    "connections": 23,
    "uptime_seconds": 864000,
    // Custom metrics per service type
    "custom": {
      "queries_per_second": 150,
      "slow_queries": 2,
      "replication_lag": 0,
      "buffer_pool_hit_ratio": 98.5
    }
  },
  
  "error": null,  // Error message if check failed
  "error_details": null,  // Stack trace or detailed error
  
  "recovery_attempted": false,
  "recovery_action": null,
  "recovery_success": null,
  "recovery_message": null,
  
  // TTL index will auto-delete old records
  "expires_at": ISODate("2025-11-12T12:00:00Z")  // 30 days retention
}
```

**Fields Description:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `service_id` | String | Yes | Reference to service |
| `host_id` | String | Yes | Reference to host (denormalized) |
| `timestamp` | Date | Yes | When check was performed |
| `check_type` | String | Yes | Type of monitoring check |
| `status` | String | Yes | Result status |
| `response_time_ms` | Number | No | Check execution time |
| `metrics` | Object | No | Performance metrics |
| `error` | String | No | Error message if failed |
| `recovery_attempted` | Boolean | Yes | Was recovery attempted |
| `expires_at` | Date | Yes | TTL for auto-deletion |

---

### 4. `environments` Collection (Optional)

Reference data for environment configurations.

```javascript
{
  "_id": ObjectId("..."),
  "env_name": "production",
  "description": "Production environment",
  "color": "#FF0000",
  "alert_severity": "critical",
  "maintenance_window": {
    "day": "Sunday",
    "start_time": "02:00",
    "end_time": "06:00",
    "timezone": "UTC"
  },
  "approval_required": true,
  "created_at": ISODate("2025-10-12T00:00:00Z")
}
```

---

## Indexes Strategy

### `hosts` Collection Indexes

```javascript
// Unique index on host_id
db.hosts.createIndex({ "host_id": 1 }, { unique: true })

// Composite index for filtering by environment and region
db.hosts.createIndex({ "environment": 1, "region": 1 })

// Index for status queries
db.hosts.createIndex({ "status": 1 })

// Index for tag-based searches
db.hosts.createIndex({ "metadata.tags": 1 })

// Index for IP address lookups
db.hosts.createIndex({ "ip_address": 1 })

// Index for hostname searches
db.hosts.createIndex({ "hostname": 1 })
```

### `services` Collection Indexes

```javascript
// Unique index on service_id
db.services.createIndex({ "service_id": 1 }, { unique: true })

// Index for finding all services on a host
db.services.createIndex({ "host_id": 1 })

// Index for finding all instances of a service type
db.services.createIndex({ "service_type": 1 })

// Composite index for environment + service type queries
db.services.createIndex({ "environment": 1, "service_type": 1 })

// Index for status monitoring
db.services.createIndex({ "current_status": 1 })

// Composite index for enabled services by status
db.services.createIndex({ "monitoring.enabled": 1, "current_status": 1 })

// Index for regional queries
db.services.createIndex({ "region": 1 })

// Index for finding services by tags
db.services.createIndex({ "tags": 1 })

// Index for last check time (useful for stale detection)
db.services.createIndex({ "last_check": 1 })
```

### `monitoring_history` Collection Indexes

```javascript
// Composite index for service history queries
db.monitoring_history.createIndex({ "service_id": 1, "timestamp": -1 })

// Composite index for host history queries
db.monitoring_history.createIndex({ "host_id": 1, "timestamp": -1 })

// Index for time-based queries
db.monitoring_history.createIndex({ "timestamp": -1 })

// Composite index for status + time queries
db.monitoring_history.createIndex({ "status": 1, "timestamp": -1 })

// Index for check type queries
db.monitoring_history.createIndex({ "check_type": 1, "timestamp": -1 })

// TTL index for automatic document expiration (30 days)
db.monitoring_history.createIndex(
  { "expires_at": 1 }, 
  { expireAfterSeconds: 0 }
)
```

---

## Python Integration

### Installation

```bash
pip install pymongo python-dotenv
```

### Database Connection Manager

```python
# db_manager.py
import os
from pymongo import MongoClient, ASCENDING, DESCENDING
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import dotenv

class MongoDBManager:
    """MongoDB connection and operations manager for service monitoring"""
    
    def __init__(self, connection_string=None, database_name="service_monitor"):
        """
        Initialize MongoDB connection
        
        Args:
            connection_string: MongoDB connection string (or from env)
            database_name: Database name
        """
        dotenv.load_dotenv()
        
        self.connection_string = connection_string or os.getenv("MONGODB_URI", "mongodb://localhost:27017/")
        self.database_name = database_name
        
        self.client = MongoClient(self.connection_string)
        self.db = self.client[self.database_name]
        
        # Collections
        self.hosts = self.db.hosts
        self.services = self.db.services
        self.monitoring_history = self.db.monitoring_history
        self.environments = self.db.environments
        
        # Create indexes on initialization
        self._create_indexes()
    
    def _create_indexes(self):
        """Create all necessary indexes"""
        
        # Hosts indexes
        self.hosts.create_index("host_id", unique=True)
        self.hosts.create_index([("environment", ASCENDING), ("region", ASCENDING)])
        self.hosts.create_index("status")
        self.hosts.create_index("metadata.tags")
        self.hosts.create_index("ip_address")
        self.hosts.create_index("hostname")
        
        # Services indexes
        self.services.create_index("service_id", unique=True)
        self.services.create_index("host_id")
        self.services.create_index("service_type")
        self.services.create_index([("environment", ASCENDING), ("service_type", ASCENDING)])
        self.services.create_index("current_status")
        self.services.create_index([("monitoring.enabled", ASCENDING), ("current_status", ASCENDING)])
        self.services.create_index("region")
        self.services.create_index("tags")
        self.services.create_index("last_check")
        
        # Monitoring history indexes
        self.monitoring_history.create_index([("service_id", ASCENDING), ("timestamp", DESCENDING)])
        self.monitoring_history.create_index([("host_id", ASCENDING), ("timestamp", DESCENDING)])
        self.monitoring_history.create_index([("timestamp", DESCENDING)])
        self.monitoring_history.create_index([("status", ASCENDING), ("timestamp", DESCENDING)])
        self.monitoring_history.create_index([("check_type", ASCENDING), ("timestamp", DESCENDING)])
        
        # TTL index for auto-deletion (30 days)
        self.monitoring_history.create_index("expires_at", expireAfterSeconds=0)
    
    # ==================== HOST OPERATIONS ====================
    
    def add_host(self, host_data: Dict) -> str:
        """
        Add a new host
        
        Args:
            host_data: Host configuration dictionary
            
        Returns:
            host_id of the created host
        """
        host_data["created_at"] = datetime.utcnow()
        host_data["updated_at"] = datetime.utcnow()
        host_data["last_seen"] = datetime.utcnow()
        
        if "status" not in host_data:
            host_data["status"] = "active"
        
        result = self.hosts.insert_one(host_data)
        return host_data["host_id"]
    
    def get_host(self, host_id: str) -> Optional[Dict]:
        """Get host by host_id"""
        return self.hosts.find_one({"host_id": host_id})
    
    def get_hosts_by_environment(self, environment: str) -> List[Dict]:
        """Get all hosts in an environment"""
        return list(self.hosts.find({"environment": environment}))
    
    def get_hosts_by_region(self, region: str) -> List[Dict]:
        """Get all hosts in a region"""
        return list(self.hosts.find({"region": region}))
    
    def update_host(self, host_id: str, update_data: Dict) -> bool:
        """Update host configuration"""
        update_data["updated_at"] = datetime.utcnow()
        result = self.hosts.update_one(
            {"host_id": host_id},
            {"$set": update_data}
        )
        return result.modified_count > 0
    
    def delete_host(self, host_id: str) -> bool:
        """Delete a host and all its services"""
        # Delete all services for this host
        self.services.delete_many({"host_id": host_id})
        # Delete host
        result = self.hosts.delete_one({"host_id": host_id})
        return result.deleted_count > 0
    
    # ==================== SERVICE OPERATIONS ====================
    
    def add_service(self, service_data: Dict) -> str:
        """
        Add a new service
        
        Args:
            service_data: Service configuration dictionary
            
        Returns:
            service_id of the created service
        """
        service_data["created_at"] = datetime.utcnow()
        service_data["updated_at"] = datetime.utcnow()
        service_data["last_check"] = datetime.utcnow()
        
        if "current_status" not in service_data:
            service_data["current_status"] = "unknown"
        
        result = self.services.insert_one(service_data)
        return service_data["service_id"]
    
    def get_service(self, service_id: str) -> Optional[Dict]:
        """Get service by service_id"""
        return self.services.find_one({"service_id": service_id})
    
    def get_services_by_host(self, host_id: str) -> List[Dict]:
        """Get all services for a specific host"""
        return list(self.services.find({"host_id": host_id}))
    
    def get_services_by_type(self, service_type: str) -> List[Dict]:
        """Get all services of a specific type (e.g., all MySQL)"""
        return list(self.services.find({"service_type": service_type}))
    
    def get_services_by_environment(self, environment: str) -> List[Dict]:
        """Get all services in an environment"""
        return list(self.services.find({"environment": environment}))
    
    def get_services_by_status(self, status: str) -> List[Dict]:
        """Get all services with a specific status"""
        return list(self.services.find({"current_status": status}))
    
    def get_enabled_services(self) -> List[Dict]:
        """Get all services with monitoring enabled"""
        return list(self.services.find({"monitoring.enabled": True}))
    
    def update_service_status(self, service_id: str, status: str, metrics: Dict = None) -> bool:
        """Update service status and optionally metrics"""
        update_data = {
            "current_status": status,
            "last_check": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # Check if status changed
        service = self.get_service(service_id)
        if service and service.get("current_status") != status:
            update_data["last_status_change"] = datetime.utcnow()
            update_data["consecutive_failures"] = 0 if status == "running" else service.get("consecutive_failures", 0) + 1
        
        result = self.services.update_one(
            {"service_id": service_id},
            {"$set": update_data}
        )
        return result.modified_count > 0
    
    def update_service(self, service_id: str, update_data: Dict) -> bool:
        """Update service configuration"""
        update_data["updated_at"] = datetime.utcnow()
        result = self.services.update_one(
            {"service_id": service_id},
            {"$set": update_data}
        )
        return result.modified_count > 0
    
    def delete_service(self, service_id: str) -> bool:
        """Delete a service"""
        result = self.services.delete_one({"service_id": service_id})
        return result.deleted_count > 0
    
    # ==================== MONITORING HISTORY OPERATIONS ====================
    
    def log_monitoring_check(self, check_data: Dict) -> str:
        """
        Log a monitoring check result
        
        Args:
            check_data: Monitoring check data
            
        Returns:
            _id of the created log entry
        """
        check_data["timestamp"] = datetime.utcnow()
        
        # Set expiration date (30 days from now)
        check_data["expires_at"] = datetime.utcnow() + timedelta(days=30)
        
        result = self.monitoring_history.insert_one(check_data)
        return str(result.inserted_id)
    
    def get_service_history(self, service_id: str, limit: int = 100) -> List[Dict]:
        """Get monitoring history for a service"""
        return list(
            self.monitoring_history.find({"service_id": service_id})
            .sort("timestamp", DESCENDING)
            .limit(limit)
        )
    
    def get_host_history(self, host_id: str, limit: int = 100) -> List[Dict]:
        """Get monitoring history for all services on a host"""
        return list(
            self.monitoring_history.find({"host_id": host_id})
            .sort("timestamp", DESCENDING)
            .limit(limit)
        )
    
    def get_recent_failures(self, hours: int = 24) -> List[Dict]:
        """Get all failed checks in the last N hours"""
        since = datetime.utcnow() - timedelta(hours=hours)
        return list(
            self.monitoring_history.find({
                "status": {"$ne": "running"},
                "timestamp": {"$gte": since}
            })
            .sort("timestamp", DESCENDING)
        )
    
    def get_service_uptime(self, service_id: str, days: int = 30) -> float:
        """
        Calculate service uptime percentage
        
        Args:
            service_id: Service ID
            days: Number of days to calculate
            
        Returns:
            Uptime percentage (0-100)
        """
        since = datetime.utcnow() - timedelta(days=days)
        
        total_checks = self.monitoring_history.count_documents({
            "service_id": service_id,
            "timestamp": {"$gte": since}
        })
        
        if total_checks == 0:
            return 0.0
        
        successful_checks = self.monitoring_history.count_documents({
            "service_id": service_id,
            "timestamp": {"$gte": since},
            "status": "running"
        })
        
        return round((successful_checks / total_checks) * 100, 2)
    
    # ==================== COMPLEX QUERIES ====================
    
    def get_dashboard_summary(self) -> Dict:
        """Get overall system summary for dashboard"""
        return {
            "total_hosts": self.hosts.count_documents({}),
            "active_hosts": self.hosts.count_documents({"status": "active"}),
            "total_services": self.services.count_documents({}),
            "running_services": self.services.count_documents({"current_status": "running"}),
            "stopped_services": self.services.count_documents({"current_status": "stopped"}),
            "error_services": self.services.count_documents({"current_status": "error"}),
            "unknown_services": self.services.count_documents({"current_status": "unknown"}),
            "by_environment": list(self.services.aggregate([
                {"$group": {"_id": "$environment", "count": {"$sum": 1}}}
            ])),
            "by_region": list(self.services.aggregate([
                {"$group": {"_id": "$region", "count": {"$sum": 1}}}
            ])),
            "by_service_type": list(self.services.aggregate([
                {"$group": {"_id": "$service_type", "count": {"$sum": 1}}}
            ]))
        }
    
    def get_services_needing_attention(self) -> Dict:
        """Get services that need attention (down, high failures, etc.)"""
        return {
            "down_services": list(self.services.find({
                "current_status": {"$in": ["stopped", "error"]}
            })),
            "high_failure_rate": list(self.services.find({
                "consecutive_failures": {"$gte": 3}
            })),
            "stale_checks": list(self.services.find({
                "last_check": {"$lt": datetime.utcnow() - timedelta(minutes=10)}
            }))
        }
    
    def close(self):
        """Close MongoDB connection"""
        self.client.close()
```

### Migration Script (JSON to MongoDB)

```python
# migrate_config.py
import json
from db_manager import MongoDBManager
from datetime import datetime

def migrate_json_to_mongodb(json_file: str, environment: str = "production", region: str = "default"):
    """
    Migrate existing config.json to MongoDB
    
    Args:
        json_file: Path to config.json
        environment: Environment name (default: production)
        region: Region name (default: default)
    """
    
    # Load JSON config
    with open(json_file, 'r') as f:
        config = json.load(f)
    
    # Initialize MongoDB manager
    db = MongoDBManager()
    
    print("Starting migration...")
    
    # Process each target
    for idx, target in enumerate(config.get("targets", [])):
        # Generate IDs
        host_id = f"host_{target['host'].replace('.', '_')}_{idx:03d}"
        service_id = f"svc_{target['host'].replace('.', '_')}_{target['service'].replace('.', '_')}_{idx:03d}"
        
        # Create host document
        host_data = {
            "host_id": host_id,
            "hostname": target["name"],
            "ip_address": target["host"],
            "environment": environment,
            "region": region,
            "location": {
                "datacenter": "default",
                "rack": None,
                "zone": None
            },
            "ssh_config": {
                "user": target["ssh"]["user"],
                "port": target["ssh"]["port"],
                "key_path": None,
                "use_sudo": target.get("use_sudo", False)
            },
            "metadata": {
                "os": "Unknown",
                "purpose": f"{target['service']} Server",
                "tags": [target["service"].split(".")[0]]
            },
            "status": "active"
        }
        
        # Check if host already exists
        existing_host = db.get_host(host_id)
        if not existing_host:
            db.add_host(host_data)
            print(f"✓ Added host: {host_id}")
        else:
            print(f"⊘ Host already exists: {host_id}")
        
        # Create service document
        service_data = {
            "service_id": service_id,
            "host_id": host_id,
            "service_name": target["service"],
            "service_type": target["service"].split(".")[0],  # e.g., "mysql" from "mysql.service"
            "display_name": f"{target['service']} on {target['name']}",
            "description": f"Monitoring for {target['service']}",
            "monitoring": {
                "method": target["method"],
                "enabled": True,
                "interval_sec": target.get("interval_sec", 60),
                "timeout_sec": 30,
                "retry_attempts": 3,
                "retry_delay_sec": 5
            },
            "recovery": {
                "recover_on_down": target.get("recover_on_down", False),
                "recover_action": target.get("recover_action", "restart"),
                "custom_script": None,
                "max_recovery_attempts": 3,
                "recovery_cooldown_sec": 300,
                "notify_before_recovery": True
            },
            "alerting": {
                "enabled": True,
                "channels": ["email"],
                "severity": "medium",
                "escalation_policy": None,
                "mute_until": None
            },
            "health_check": {
                "enabled": False,
                "endpoint": None,
                "expected_response": None,
                "custom_check": None
            },
            "current_status": "unknown",
            "uptime_percentage": 0.0,
            "consecutive_failures": 0,
            "environment": environment,
            "region": region,
            "tags": [target["service"].split(".")[0]],
            "dependencies": []
        }
        
        # Check if service already exists
        existing_service = db.get_service(service_id)
        if not existing_service:
            db.add_service(service_data)
            print(f"✓ Added service: {service_id}")
        else:
            print(f"⊘ Service already exists: {service_id}")
    
    print(f"\nMigration complete!")
    print(f"Total targets processed: {len(config.get('targets', []))}")
    
    # Print summary
    summary = db.get_dashboard_summary()
    print(f"\nDatabase Summary:")
    print(f"  Hosts: {summary['total_hosts']}")
    print(f"  Services: {summary['total_services']}")
    
    db.close()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Migrate config.json to MongoDB')
    parser.add_argument('json_file', help='Path to config.json')
    parser.add_argument('--environment', default='production', help='Environment name')
    parser.add_argument('--region', default='default', help='Region name')
    
    args = parser.parse_args()
    
    migrate_json_to_mongodb(args.json_file, args.environment, args.region)
```

### Integration with Existing Monitor

```python
# Updated monitor integration
from db_manager import MongoDBManager
from datetime import datetime

def run_monitoring_cycle():
    """Run a complete monitoring cycle for all enabled services"""
    
    db = MongoDBManager()
    
    # Get all enabled services
    services = db.get_enabled_services()
    
    print(f"Starting monitoring cycle for {len(services)} services...")
    
    for service in services:
        # Get host information
        host = db.get_host(service["host_id"])
        if not host:
            print(f"⚠ Host not found for service: {service['service_id']}")
            continue
        
        print(f"\nChecking: {service['display_name']} on {host['hostname']}")
        
        try:
            # Run your monitoring check here
            # This is where you'd use your DatabaseMonitor class or SSH commands
            status, metrics, error = check_service_status(host, service)
            
            # Update service status
            db.update_service_status(service["service_id"], status, metrics)
            
            # Log to history
            history_entry = {
                "service_id": service["service_id"],
                "host_id": service["host_id"],
                "check_type": "status_check",
                "status": status,
                "response_time_ms": metrics.get("response_time_ms", 0),
                "metrics": metrics,
                "error": error,
                "recovery_attempted": False,
                "recovery_success": None
            }
            
            db.log_monitoring_check(history_entry)
            
            # Handle recovery if needed
            if status != "running" and service["recovery"]["recover_on_down"]:
                print(f"  ⚠ Service is {status}, attempting recovery...")
                recovery_success = attempt_recovery(host, service)
                
                # Log recovery attempt
                history_entry["recovery_attempted"] = True
                history_entry["recovery_success"] = recovery_success
                db.log_monitoring_check(history_entry)
            
            print(f"  ✓ Status: {status}")
            
        except Exception as e:
            print(f"  ✗ Error checking service: {e}")
            
            # Log error
            db.log_monitoring_check({
                "service_id": service["service_id"],
                "host_id": service["host_id"],
                "check_type": "status_check",
                "status": "error",
                "error": str(e),
                "recovery_attempted": False
            })
    
    db.close()
    print("\nMonitoring cycle complete!")

def check_service_status(host, service):
    """
    Check service status - integrate with your existing monitoring code
    
    Returns:
        (status, metrics, error)
    """
    # Implement your actual check logic here
    # This would call your DatabaseMonitor class or SSH commands
    pass

def attempt_recovery(host, service):
    """
    Attempt to recover a failed service
    
    Returns:
        bool: True if recovery successful
    """
    # Implement your recovery logic here
    pass

if __name__ == "__main__":
    run_monitoring_cycle()
```

---

## Common Queries

### Query Examples

```python
from db_manager import MongoDBManager

db = MongoDBManager()

# 1. Get all MySQL services in production
mysql_services = db.services.find({
    "service_type": "mysql",
    "environment": "production"
})

# 2. Find all down services
down_services = db.get_services_by_status("stopped")

# 3. Get services on a specific host
services_on_host = db.get_services_by_host("host_jeju_mysql_001")

# 4. Find services with high failure rate
critical_services = list(db.services.find({
    "consecutive_failures": {"$gte": 3},
    "monitoring.enabled": True
}))

# 5. Get all services in Asia-Pacific region
apac_services = list(db.services.find({"region": "asia-pacific"}))

# 6. Find stale services (not checked recently)
from datetime import datetime, timedelta
stale_threshold = datetime.utcnow() - timedelta(minutes=10)
stale_services = list(db.services.find({
    "last_check": {"$lt": stale_threshold}
}))

# 7. Get monitoring history for last 24 hours
recent_history = db.get_recent_failures(hours=24)

# 8. Calculate uptime for a service
uptime = db.get_service_uptime("svc_jeju_mysql_001", days=30)
print(f"Uptime: {uptime}%")

# 9. Get dashboard summary
summary = db.get_dashboard_summary()

# 10. Services grouped by status
status_summary = list(db.services.aggregate([
    {
        "$group": {
            "_id": "$current_status",
            "count": {"$sum": 1},
            "services": {"$push": "$service_name"}
        }
    }
]))

db.close()
```

---

## Best Practices

### 1. **ID Generation**
- Use meaningful, readable IDs: `host_jeju_mysql_001`, `svc_jeju_mysql_001`
- Include environment or region in ID if needed: `host_prod_us_east_db01`
- Maintain consistency across your infrastructure

### 2. **Denormalization**
- Store `environment` and `region` in both hosts and services for query performance
- Accept slight data duplication for read optimization
- Update denormalized data when parent changes

### 3. **TTL for History**
- Use TTL indexes to auto-delete old monitoring data
- Adjust retention period based on compliance requirements (default: 30 days)
- For long-term analytics, archive to cold storage

### 4. **Incremental Updates**
```python
# Good: Update only changed fields
db.services.update_one(
    {"service_id": "svc_001"},
    {"$set": {"monitoring.interval_sec": 60}}
)

# Avoid: Replacing entire document
# db.services.replace_one({"service_id": "svc_001"}, entire_doc)
```

### 5. **Batch Operations**
```python
# For multiple updates, use bulk operations
from pymongo import UpdateOne

bulk_ops = [
    UpdateOne(
        {"service_id": "svc_001"},
        {"$set": {"current_status": "running"}}
    ),
    UpdateOne(
        {"service_id": "svc_002"},
        {"$set": {"current_status": "stopped"}}
    )
]

db.services.bulk_write(bulk_ops)
```

### 6. **Error Handling**
```python
from pymongo.errors import DuplicateKeyError, ConnectionFailure

try:
    db.add_service(service_data)
except DuplicateKeyError:
    print("Service already exists")
except ConnectionFailure:
    print("Cannot connect to MongoDB")
```

### 7. **Connection Pooling**
```python
# MongoDB Python driver handles connection pooling automatically
# Configure in connection string:
client = MongoClient(
    "mongodb://localhost:27017/",
    maxPoolSize=50,
    minPoolSize=10,
    maxIdleTimeMS=45000
)
```

### 8. **Monitoring MongoDB Itself**
- Monitor MongoDB performance with `db.serverStatus()`
- Track collection sizes and index usage
- Set up alerts for connection pool exhaustion
- Monitor replication lag if using replica sets

### 9. **Backup Strategy**
```bash
# Regular backups
mongodump --uri="mongodb://localhost:27017/service_monitor" --out=/backup/$(date +%Y%m%d)

# Restore
mongorestore --uri="mongodb://localhost:27017/service_monitor" /backup/20251012
```

### 10. **Security**
- Use authentication: enable auth in MongoDB config
- Create specific users with minimum required permissions
- Use SSL/TLS for connections
- Store credentials in environment variables or secrets manager
- Never commit connection strings to version control

```python
# Example .env file
MONGODB_URI=mongodb://user:password@localhost:27017/service_monitor?authSource=admin
MONGODB_DATABASE=service_monitor
```

---

## Environment Variables Setup

Create a `.env` file:

```bash
# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/
MONGODB_DATABASE=service_monitor

# Optional: If using authentication
MONGODB_USER=monitor_user
MONGODB_PASSWORD=secure_password

# Monitoring Settings
DEFAULT_CHECK_INTERVAL=60
HISTORY_RETENTION_DAYS=30
MAX_RECOVERY_ATTEMPTS=3
```

---

## Usage Example

```bash
# 1. Migrate existing config
python migrate_config.py config.json --environment production --region us-east-1

# 2. Run monitoring cycle
python run_monitoring_cycle.py

# 3. Query status
python -c "from db_manager import MongoDBManager; db = MongoDBManager(); print(db.get_dashboard_summary())"
```

---

## Next Steps

1. **Implement monitoring loop** - Create scheduled job (cron/systemd timer)
2. **Add alerting** - Integrate Slack/Email/PagerDuty
3. **Build dashboard** - Create web UI for visualization
4. **Add API** - REST API for external integrations
5. **Metrics aggregation** - Real-time analytics and reporting
6. **Auto-scaling** - Adjust check intervals based on load
7. **Machine learning** - Anomaly detection for unusual patterns

---

## Troubleshooting

### Issue: Duplicate Key Error
```python
# Solution: Check if host/service already exists before inserting
existing = db.get_host("host_001")
if existing:
    db.update_host("host_001", update_data)
else:
    db.add_host(host_data)
```

### Issue: Slow Queries
```python
# Solution: Analyze query with explain()
db.services.find({"environment": "production"}).explain()

# Create appropriate indexes
db.services.create_index("environment")
```

### Issue: TTL Not Deleting Documents
```bash
# Check if TTL monitor is running
db.serverStatus().metrics.ttl

# Manually trigger (for testing)
db.runCommand({compact: 'monitoring_history'})
```

---

## License

This schema design is provided as-is for service monitoring applications.

## Questions or Improvements?

Feel free to adapt this schema to your specific needs. Key areas for customization:
- Adjust retention periods
- Add custom metrics fields
- Extend alerting configuration
- Add authentication/authorization
- Implement audit logging

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-12  
**Author:** Database Monitoring System Team