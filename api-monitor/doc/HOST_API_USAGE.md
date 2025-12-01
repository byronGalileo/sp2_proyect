# Service Monitor API - Usage Guide

## Overview

The Service Monitor API v2.0 provides comprehensive endpoints for managing hosts, services, and monitoring configurations. It integrates with your systemctl-based monitoring system by generating configuration files from the database.

## Base URL

```
http://localhost:8000
```

## API Documentation

Interactive API documentation is available at:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## Quick Start

### 1. Setup Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit with your MongoDB credentials
nano .env
```

### 2. Install Dependencies

```bash
pip install -r requirements_mongodb.txt
```

### 3. Start the API

```bash
cd api
python main.py --host 0.0.0.0 --port 8000
```

Or with auto-reload for development:

```bash
python main.py --reload
```

---

## API Endpoints

### Health Check

#### GET `/health`
Check API and database health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-12T12:00:00Z",
  "database": {
    "connected": true,
    "database_name": "service_monitoring",
    "collections": {
      "logs": "logs",
      "events": "events"
    }
  }
}
```

---

## Host Management

### Create Host

#### POST `/hosts`

Create a new host/server in the system.

**Request Body:**
```json
{
  "host_id": "host_mysql_prod_001",
  "hostname": "mysql-server-01",
  "ip_address": "10.1.11.81",
  "environment": "production",
  "region": "us-east-1",
  "ssh_config": {
    "user": "ubuntu",
    "port": 22,
    "key_path": "/path/to/key.pem",
    "use_sudo": true,
    "credentials": {
      "password": "your_sudo_password"
    }
  },
  "location": {
    "datacenter": "AWS-US-EAST-1",
    "rack": "A-12",
    "zone": "zone-1a"
  },
  "metadata": {
    "os": "Ubuntu 22.04",
    "purpose": "Database Server",
    "tags": ["mysql", "critical", "production"]
  },
  "status": "active"
}
```

**SSH Config Fields:**
- `user` (required): SSH username
- `port` (optional, default: 22): SSH port
- `key_path` (optional): Path to SSH private key file
- `use_sudo` (optional, default: false): Whether to use sudo for systemctl commands
- `credentials` (optional): Authentication credentials
  - `password` (optional): Password for sudo authentication (used with `sudo -S`)

**Response:**
```json
{
  "success": true,
  "message": "Host 'host_mysql_prod_001' created successfully",
  "data": {
    "host_id": "host_mysql_prod_001"
  }
}
```

### Get All Hosts

#### GET `/hosts`

Get all hosts with optional filters.

**Query Parameters:**
- `environment` (optional): Filter by environment (e.g., production, staging, dev)
- `region` (optional): Filter by region
- `status` (optional): Filter by status (active, maintenance, decommissioned)
- `limit` (optional, default: 100): Maximum results
- `skip` (optional, default: 0): Results to skip (pagination)

**Example:**
```bash
curl "http://localhost:8000/hosts?environment=production&limit=50"
```

**Response:**
```json
{
  "success": true,
  "message": "Retrieved 2 hosts",
  "data": {
    "hosts": [...],
    "count": 2
  }
}
```

### Get Specific Host

#### GET `/hosts/{host_id}`

Get details of a specific host.

**Example:**
```bash
curl "http://localhost:8000/hosts/host_mysql_prod_001"
```

### Update Host

#### PUT `/hosts/{host_id}`

Update host information.

**Request Body:**
```json
{
  "hostname": "mysql-server-01-updated",
  "status": "maintenance",
  "metadata": {
    "os": "Ubuntu 24.04",
    "purpose": "Primary Database Server",
    "tags": ["mysql", "critical", "production", "upgraded"]
  }
}
```

### Delete Host

#### DELETE `/hosts/{host_id}`

Delete a host and optionally its associated services.

**Query Parameters:**
- `delete_services` (default: true): Also delete associated services

**Example:**
```bash
curl -X DELETE "http://localhost:8000/hosts/host_mysql_prod_001?delete_services=true"
```

### Get Metadata

#### GET `/hosts/metadata/environments`
Get list of all unique environments.

#### GET `/hosts/metadata/regions`
Get list of all unique regions.

---

## Service Management

### Create Service

#### POST `/services`

Create a new service monitoring configuration.

**Request Body:**
```json
{
  "service_id": "svc_mysql_prod_001",
  "host_id": "host_mysql_prod_001",
  "service_name": "mysql",
  "service_type": "mysql",
  "display_name": "MySQL Production Database",
  "description": "Primary MySQL database instance",
  "environment": "production",
  "region": "us-east-1",
  "monitoring": {
    "method": "ssh",
    "enabled": true,
    "interval_sec": 60,
    "timeout_sec": 30,
    "retry_attempts": 3,
    "retry_delay_sec": 5
  },
  "recovery": {
    "recover_on_down": true,
    "recover_action": "restart",
    "max_recovery_attempts": 3,
    "recovery_cooldown_sec": 300,
    "notify_before_recovery": true
  },
  "alerting": {
    "enabled": true,
    "channels": ["email", "slack"],
    "severity": "high"
  },
  "tags": ["database", "mysql", "critical"],
  "dependencies": []
}
```

**Note:**
- The `service_name` will automatically have `.service` appended if not present
- When generating config.json, `.service` is removed for systemctl compatibility

**Response:**
```json
{
  "success": true,
  "message": "Service 'svc_mysql_prod_001' created successfully",
  "data": {
    "service_id": "svc_mysql_prod_001"
  }
}
```

### Get All Services

#### GET `/services`

Get all services with optional filters.

**Query Parameters:**
- `host_id` (optional): Filter by host
- `service_type` (optional): Filter by service type (mysql, nginx, etc.)
- `environment` (optional): Filter by environment
- `region` (optional): Filter by region
- `status` (optional): Filter by status (running, stopped, error, unknown)
- `enabled_only` (optional, default: false): Only enabled services
- `limit` (optional, default: 100): Maximum results
- `skip` (optional, default: 0): Results to skip

**Example:**
```bash
curl "http://localhost:8000/services?environment=production&service_type=mysql"
```

### Get Specific Service

#### GET `/services/{service_id}`

Get details of a specific service.

### Update Service

#### PUT `/services/{service_id}`

Update service configuration.

**Request Body:**
```json
{
  "monitoring": {
    "enabled": true,
    "interval_sec": 45
  },
  "recovery": {
    "recover_on_down": true,
    "max_recovery_attempts": 5
  }
}
```

### Delete Service

#### DELETE `/services/{service_id}`

Delete a service.

### Dashboard Summary

#### GET `/services/dashboard/summary`

Get overall service statistics for dashboard.

**Response:**
```json
{
  "success": true,
  "message": "Dashboard summary retrieved successfully",
  "data": {
    "total_services": 10,
    "running_services": 8,
    "stopped_services": 1,
    "error_services": 1,
    "unknown_services": 0,
    "by_environment": [
      {"_id": "production", "count": 7},
      {"_id": "staging", "count": 3}
    ],
    "by_region": [
      {"_id": "us-east-1", "count": 6},
      {"_id": "us-west-2", "count": 4}
    ],
    "by_service_type": [
      {"_id": "mysql", "count": 3},
      {"_id": "nginx", "count": 4},
      {"_id": "redis", "count": 3}
    ]
  }
}
```

### Services Needing Attention

#### GET `/services/attention/needed`

Get services that need attention (down, high failures, stale checks).

**Response:**
```json
{
  "success": true,
  "data": {
    "down_services": [...],
    "high_failure_rate": [...],
    "stale_checks": [...]
  }
}
```

---

## Configuration Generation

### Generate Config

#### GET `/config/generate`

Generate monitoring config.json from database.

**Query Parameters:**
- `environment` (optional): Filter by environment
- `region` (optional): Filter by region
- `enabled_only` (optional, default: true): Only include enabled services

**Example:**
```bash
curl "http://localhost:8000/config/generate?environment=production"
```

**Response:**
```json
{
  "success": true,
  "message": "Generated config for 5 services",
  "data": {
    "targets": [
      {
        "name": "MySQL Production Database",
        "host": "10.1.11.81",
        "service": "mysql",
        "ssh": {
          "user": "ubuntu",
          "port": 22
        },
        "method": "ssh",
        "interval_sec": 60,
        "recover_on_down": true,
        "recover_action": "restart",
        "use_sudo": true
      }
    ]
  }
}
```

### Download Config

#### GET `/config/download`

Download config.json as a file.

**Query Parameters:** Same as `/config/generate`

**Example:**
```bash
curl "http://localhost:8000/config/download?environment=production" -o config.json
```

---

## Complete Workflow Example

### 1. Create a Host

```bash
curl -X POST "http://localhost:8000/hosts" \
  -H "Content-Type: application/json" \
  -d '{
    "host_id": "host_web_prod_001",
    "hostname": "web-server-01",
    "ip_address": "192.168.1.100",
    "environment": "production",
    "region": "us-east-1",
    "ssh_config": {
      "user": "ubuntu",
      "port": 22,
      "use_sudo": true,
      "credentials": {
        "password": "your_sudo_password"
      }
    },
    "metadata": {
      "os": "Ubuntu 22.04",
      "purpose": "Web Server",
      "tags": ["nginx", "production"]
    }
  }'
```

### 2. Create Services for the Host

```bash
# Create Nginx service
curl -X POST "http://localhost:8000/services" \
  -H "Content-Type: application/json" \
  -d '{
    "service_id": "svc_nginx_prod_001",
    "host_id": "host_web_prod_001",
    "service_name": "nginx",
    "service_type": "nginx",
    "display_name": "Nginx Web Server",
    "monitoring": {
      "enabled": true,
      "interval_sec": 45
    },
    "recovery": {
      "recover_on_down": true,
      "recover_action": "restart"
    },
    "tags": ["web", "nginx"]
  }'

# Create Redis service
curl -X POST "http://localhost:8000/services" \
  -H "Content-Type: application/json" \
  -d '{
    "service_id": "svc_redis_prod_001",
    "host_id": "host_web_prod_001",
    "service_name": "redis",
    "service_type": "redis",
    "display_name": "Redis Cache",
    "monitoring": {
      "enabled": true,
      "interval_sec": 60
    },
    "recovery": {
      "recover_on_down": false
    },
    "tags": ["cache", "redis"]
  }'
```

### 3. Generate Monitoring Config

```bash
# Generate and download config.json
curl "http://localhost:8000/config/download?environment=production" -o config.json

# View the generated config
cat config.json
```

### 4. Use Config with Your Monitor

```bash
# Your monitoring script can now use this config
./monitor.py --config config.json
```

### 5. Query Services

```bash
# Get all services on the host
curl "http://localhost:8000/services?host_id=host_web_prod_001"

# Get dashboard summary
curl "http://localhost:8000/services/dashboard/summary"

# Check services needing attention
curl "http://localhost:8000/services/attention/needed"
```

---

## Python Client Example

```python
import requests

API_BASE = "http://localhost:8000"

# Create a host
host_data = {
    "host_id": "host_app_prod_001",
    "hostname": "app-server-01",
    "ip_address": "10.0.1.50",
    "environment": "production",
    "region": "us-west-2",
    "ssh_config": {
        "user": "ubuntu",
        "port": 22,
        "use_sudo": True,
        "credentials": {
            "password": "your_sudo_password"
        }
    }
}

response = requests.post(f"{API_BASE}/hosts", json=host_data)
print(response.json())

# Create a service
service_data = {
    "service_id": "svc_app_prod_001",
    "host_id": "host_app_prod_001",
    "service_name": "myapp",
    "service_type": "application",
    "monitoring": {
        "enabled": True,
        "interval_sec": 60
    },
    "recovery": {
        "recover_on_down": True,
        "recover_action": "restart"
    }
}

response = requests.post(f"{API_BASE}/services", json=service_data)
print(response.json())

# Generate config
response = requests.get(f"{API_BASE}/config/generate", params={"environment": "production"})
config = response.json()
print(config)

# Download config file
response = requests.get(f"{API_BASE}/config/download", params={"environment": "production"})
with open("config.json", "w") as f:
    f.write(response.text)
```

---

## Environment and Region Management

The API automatically tracks unique environments and regions:

```bash
# Get all environments
curl "http://localhost:8000/hosts/metadata/environments"

# Get all regions
curl "http://localhost:8000/hosts/metadata/regions"
```

This allows you to:
- Organize hosts by environment (dev, staging, production)
- Group services by region (us-east-1, us-west-2, eu-central-1)
- Generate environment-specific configs
- Filter queries by environment/region

---

## Default Values

When creating services, these defaults are applied if not specified:

- `environment`: "production"
- `region`: "default"
- `monitoring.method`: "ssh"
- `monitoring.enabled`: true
- `monitoring.interval_sec`: 60
- `monitoring.timeout_sec`: 30
- `monitoring.retry_attempts`: 3
- `recovery.recover_on_down`: false
- `recovery.recover_action`: "restart"
- `recovery.max_recovery_attempts`: 3
- `alerting.enabled`: true
- `alerting.severity`: "medium"

---

## Service Name Convention

- Services are stored with `.service` extension in the database
- When generating config.json, the `.service` extension is automatically removed
- If you create a service with name "mysql", it's stored as "mysql.service"
- In config.json, it appears as "mysql" for systemctl compatibility

---

## Error Handling

All endpoints return standard error responses:

```json
{
  "detail": "Error message describing what went wrong"
}
```

Common HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad request (invalid input)
- `404`: Not found
- `409`: Conflict (duplicate ID)
- `500`: Server error

---

## Next Steps

1. **Set up monitoring script** to use generated config.json
2. **Implement logging** to monitoring_history collection after checks
3. **Configure alerting** channels (email, Slack, PagerDuty)
4. **Build dashboard** UI to visualize service health
5. **Add authentication** for production deployment

---

## Credentials and Authentication

### Using Sudo with Password

When `use_sudo` is enabled and credentials are provided, the system uses `sudo -S` to execute systemctl commands with the provided password.

**Example Configuration:**
```json
{
  "ssh_config": {
    "user": "ubuntu",
    "port": 22,
    "use_sudo": true,
    "credentials": {
      "password": "your_sudo_password"
    }
  }
}
```

**Generated Config Output:**
```json
{
  "targets": [
    {
      "host": "web-server",
      "name": "nginx",
      "service": "nginx.service",
      "use_sudo": true,
      "credentials": {
        "password": "your_sudo_password"
      }
    }
  ]
}
```

**How it works:**
1. Monitor reads the credentials from config.json
2. When service needs remediation, it uses: `echo 'password' | sudo -S systemctl restart service`
3. Password is passed securely through stdin to sudo

### Security Considerations

**Important Security Notes:**
- Passwords are stored in plain text in the database and config files
- Ensure proper file permissions: `chmod 600 config.json`
- Use SSH keys when possible instead of passwords
- Consider using NOPASSWD in sudoers for monitoring user
- For production, consider using secrets management (HashiCorp Vault, AWS Secrets Manager)

**Alternative: SSH Keys with NOPASSWD Sudo**
```json
{
  "ssh_config": {
    "user": "ubuntu",
    "port": 22,
    "key_path": "/home/user/.ssh/monitoring_key",
    "use_sudo": true
  }
}
```

Then configure sudoers on the target host:
```bash
# /etc/sudoers.d/monitoring
ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart *, /bin/systemctl start *, /bin/systemctl stop *
```

### Local vs SSH Methods

**Local Method:**
- Runs on the same machine as the monitor
- Uses local systemctl commands
- Credentials used for `sudo -S` if `use_sudo: true`

**SSH Method:**
- Connects to remote hosts via SSH
- Uses SSH keys for authentication
- Credentials not typically used (SSH handles auth)
- `use_sudo` applies to remote systemctl commands

---

## Support

For issues or questions:
1. Check API documentation at `/docs`
2. Review MongoDB schema in `mongodb_schema_doc.md`
3. Examine example requests in this guide
