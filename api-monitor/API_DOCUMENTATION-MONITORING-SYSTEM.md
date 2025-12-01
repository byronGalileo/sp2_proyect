# Service Monitoring System v2.0 - Comprehensive Manual

**Status**: Production-Ready (Core) | **Version**: 2.0.0 | **Stack**: Python 3.13, FastAPI, MongoDB

---

## 📚 Table of Contents

1.  [Executive Summary](#1-executive-summary)
2.  [System Architecture](#2-system-architecture)
    *   [Component Diagram](#component-diagram)
    *   [Directory Structure](#directory-structure)
    *   [Router Architecture](#router-architecture)
3.  [Technical Implementation](#3-technical-implementation)
    *   [Database Schema](#database-schema)
    *   [Class Design](#class-design)
4.  [Installation & Setup](#4-installation--setup)
    *   [Prerequisites](#prerequisites)
    *   [Environment Setup](#environment-setup)
    *   [Systemd Integration](#systemd-integration)
5.  [Configuration Guide](#5-configuration-guide)
    *   [Monitor Config (`config.json`)](#monitor-config-configjson)
    *   [Environment Variables (`.env`)](#environment-variables-env)
    *   [Notification Config](#notification-config)
6.  [API Reference Manual](#6-api-reference-manual)
    *   [Hosts Router](#hosts-router)
    *   [Services Router](#services-router)
    *   [Logs Router](#logs-router)
    *   [Config Router](#config-router)
    *   [Monitoring Router](#monitoring-router)
    *   [Notifications Router](#notifications-router)
7.  [Operations & Usage](#7-operations--usage)
    *   [CLI Commands](#cli-commands)
    *   [Workflows](#workflows)
    *   [Troubleshooting](#troubleshooting)
8.  [Future Roadmap (Firebase)](#8-future-roadmap-firebase)

---

## 1. Executive Summary

The Service Monitoring System is a comprehensive solution for monitoring the health of local and remote (SSH) Linux services. It combines a robust Python-based monitoring engine with a modern REST API and MongoDB storage.

**Key Capabilities:**
*   **Dual Logging**: Simultaneously writes to traditional log files and structured MongoDB collections.
*   **Auto-Remediation**: Automatically attempts to restart failed services based on configurable policies.
*   **Modular Architecture**: Clean separation between the Monitor Core, API Layer, and Database Layer.
*   **Multi-Method Monitoring**: Supports `systemctl` checks locally and via SSH for remote servers.
*   **Notification System**: Integrated SMS alerts via AWS SNS or Twilio.

---

## 2. System Architecture

### Component Diagram

```
+-----------------+       +-----------------+
|   User / Admin  |       |   User Phone    |
+--------+--------+       +--------+--------+
         |                         ^
         | HTTP/REST               | SMS
         v                         |
+--------+--------+       +--------+--------+
|  FastAPI Server |       |   AWS / Twilio  |
+--------+--------+       +--------+--------+
         |                         ^
         | Read/Write              | API
         v                         |
+--------+--------+       +--------+--------+
|  MongoDB Atlas  |<-------+  Notification  |
|    (Database)   | Logs   |    Manager     |
+--------+--------+       +--------+--------+
         ^                         ^
         | Config/Logs             | Alerts
         |                         |
+--------+--------+                |
| Monitor Process +----------------+
+--------+--------+
         |
         | Checks (Subprocess/SSH)
         v
+-----------------------------------+
|        Monitoring Targets         |
| +-------+  +-------+  +-------+   |
| | Local |  | Remote|  | Remote|   |
| |Service|  | Host 1|  | Host 2|   |
| +-------+  +-------+  +-------+   |
+-----------------------------------+
```

### Directory Structure

```
sp2_proyect/
├── api/                          # FastAPI REST API
│   ├── main.py                  # App entry point
│   ├── routers.py               # Core Route Definitions
│   ├── notification_router.py   # Notification Management Routes
│   └── __init__.py
├── database/                    # MongoDB Layer
│   ├── connection.py            # Connection & Indexing
│   ├── config.py                # DB Configuration
│   ├── models.py                # Legacy Models
│   ├── monitoring_models.py     # Pydantic Models (Host, Service)
│   ├── operations.py            # General Log Operations
│   ├── host_operations.py       # Host CRUD
│   ├── service_operations.py    # Service CRUD
│   ├── monitoring_operations.py # Monitor Status Operations
│   └── service_operations.py    # Service CRUD
├── monitor/                     # Monitoring Engine
│   ├── monitor.py               # Main Script
│   ├── run_monitor.sh           # Execution Wrapper
│   ├── svcctl-monitor.service   # Systemd Unit File
│   ├── core/
│   │   ├── config_loader.py     # Config Parsing
│   │   ├── service_checker.py   # Status Logic (Local/SSH)
│   │   ├── logger_manager.py    # Dual Logging (File/Mongo)
│   │   └── service_monitor.py   # Orchestrator
│   └── config/
│       └── config.json          # Active Configuration
├── notifications/               # Notification System
│   ├── notification_manager.py  # Alert Logic & Cooldowns
│   ├── aws_sns_service.py       # AWS SNS Provider
│   ├── models.py                # Notification Models
│   └── providers/               # Provider Interfaces
├── port-check/                  # Utilities
│   └── port_health_check.py     # Port Connectivity Tester
├── .env                         # Environment Variables (Secrets)
├── requirements_mongodb.txt     # Project Dependencies
├── run_api.sh                   # API Startup Script
└── run_database_example.sh      # DB Connection Test Script
```

### Router Architecture

The API (`api/routers.py`) is organized into 4 main router groups, handling distinct domains of the system:

1.  **Hosts Router (`/hosts`)**
    *   Manages server inventory and SSH configurations.
    *   Handles metadata (environments, regions).
    *   *Key Endpoints*: `POST /hosts`, `GET /hosts`, `DELETE /hosts/{id}`.

2.  **Services Router (`/services`)**
    *   Manages monitoring definitions for specific systemd services.
    *   Links services to hosts.
    *   Provides dashboard statistics.
    *   *Key Endpoints*: `POST /services`, `GET /services/dashboard/summary`.

3.  **Config Router (`/config`)**
    *   Bridges the Database and the Monitor.
    *   Generates `config.json` files dynamically based on DB state.
    *   *Key Endpoints*: `GET /config/generate`, `GET /config/download`.

4.  **Monitoring Router (`/monitoring`)**
    *   Controls the monitor process itself (Start/Stop/Status).
    *   Future expansion for real-time control.
    *   *Key Endpoints*: `GET /monitoring/status`, `POST /monitoring/start`.

---

## 3. Technical Implementation

### Database Schema

The system uses 5 main MongoDB collections:

1.  **`hosts`**: Server configurations.
    *   *Index*: `host_id` (Unique), `environment`, `region`.
2.  **`services`**: Monitoring policies.
    *   *Index*: `service_id` (Unique), `host_id`, `service_type`.
3.  **`logs`**: High-volume check results.
    *   *Index*: `timestamp`, `service_name`, `sent_to_user`.
4.  **`events`**: Significant state changes (Restarts, Errors).
    *   *Index*: `event_type`, `severity`.
5.  **`monitoring_history`**: Time-series data.
    *   *Index*: `timestamp` (TTL 30 days).

### Class Design

*   **`LoggerManager`** (`monitor/core/logger_manager.py`):
    *   Unified interface for logging.
    *   Writes to `RotatingFileHandler` (disk).
    *   Writes to `AsyncIOMotorClient` (MongoDB).
*   **`ServiceChecker`** (`monitor/core/service_checker.py`):
    *   Executes `systemctl is-active` commands.
    *   Handles `subprocess` calls for Local and SSH methods.
    *   Implements retry logic and timeout handling.

---

## 4. Installation & Setup

### Prerequisites
*   Python 3.13+
*   MongoDB (Atlas or Local v4.4+)
*   SSH Access (for remote monitoring)

### Environment Setup

```bash
# 1. Create Virtual Environment
python3 -m venv venv
source venv/bin/activate

# 2. Install Dependencies
pip install -r requirements_mongodb.txt
```

### Systemd Integration

To run the monitor as a background daemon:

**File**: `/etc/systemd/system/svcctl-monitor.service`

```ini
[Unit]
Description=Service Monitor (systemd watchdog)
After=network-online.target

[Service]
WorkingDirectory=/opt/service-monitor
ExecStart=/usr/bin/python3 /opt/service-monitor/monitor.py --config config/config.json
Restart=on-failure
User=svcctl
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

Enable it:
```bash
sudo systemctl enable svcctl-monitor.service
sudo systemctl start svcctl-monitor.service
```

---

## 5. Configuration Guide

### Monitor Config (`config.json`)

The core configuration file for the monitoring engine.

```json
{
  "log_file": "logs/service_monitor.log",
  "log_level": "INFO",
  "mongodb": {
    "enabled": true,
    "host": "localhost",
    "port": 27017,
    "database": "service_monitoring"
  },
  "targets": [
    {
      "name": "nginx-prod",
      "method": "ssh",
      "host": "10.0.0.100",
      "service": "nginx.service",
      "interval_sec": 30,
      "recover_on_down": true,
      "recover_action": "restart",
      "ssh": {
        "user": "ubuntu",
        "port": 22,
        "use_sudo": true,
        "key_path": "/home/user/.ssh/id_rsa"
      }
    }
  ]
}
```

### Environment Variables (`.env`)

```bash
# MongoDB
MONGO_HOST=cluster0.mongodb.net
MONGO_USERNAME=user
MONGO_PASSWORD=pass
MONGO_DB_NAME=service_monitoring

# Notifications (Optional)
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
TWILIO_ACCOUNT_SID=xxx
TWILIO_AUTH_TOKEN=xxx
```

### Notification Config

Configure alerts via the API (stored in MongoDB).

```json
{
  "service_name": "mysql.service",
  "host": "db-01",
  "sms_provider": "twilio",
  "cooldown_minutes": 5,
  "contacts": [
    {
      "name": "Admin",
      "phone": "+15551234567",
      "notify_on": ["service_down", "service_restart_failed"]
    }
  ]
}
```

---

## 6. API Reference Manual

**Base URL**: `http://localhost:8000` | **Docs**: `/docs`

### Hosts Router

#### Create Host (`POST /hosts`)
Registers a new server.

**Request:**
```json
{
  "host_id": "web-01",
  "hostname": "web-server-01",
  "ip_address": "192.168.1.10",
  "environment": "production",
  "ssh_config": {
    "user": "ubuntu",
    "use_sudo": true
  }
}
```

#### Get All Hosts (`GET /hosts`)
*Params*: `environment`, `region`
*Response*: List of host objects.

### Services Router

#### Create Service (`POST /services`)
Adds a service to be monitored.

**Request:**
```json
{
  "service_id": "nginx-web-01",
  "host_id": "web-01",
  "service_name": "nginx",
  "monitoring": {
    "enabled": true,
    "interval_sec": 30
  },
  "recovery": {
    "recover_on_down": true,
    "recover_action": "restart"
  }
}
```
*Note*: `service_name` will auto-append `.service` if missing.

#### Dashboard Summary (`GET /services/dashboard/summary`)
Returns aggregated stats (Total, Running, Stopped, Error) for UI dashboards.

### Logs Router

#### Query Logs (`GET /logs`)
*Params*: `service_name`, `log_level`, `hours`, `limit`.

**Response:**
```json
{
  "logs": [
    {
      "timestamp": "2025-11-28T10:00:00Z",
      "service_name": "nginx",
      "message": "status=active",
      "log_level": "INFO"
    }
  ]
}
```

#### Unsent Logs (`GET /logs/unsent`)
Retrieves logs that haven't been pushed to the user (for notifications).

### Config Router

#### Generate Config (`GET /config/generate`)
Generates a `config.json` compatible with the Monitor Core from the DB.

*Params*: `environment` (e.g., `production`).

**Response:**
```json
{
  "targets": [ ... list of targets generated from Services collection ... ]
}
```

### Notifications Router

#### Test SMS (`POST /notifications/test/sms`)
Sends a test message.

**Request:**
```json
{
  "phone_number": "+15551234567",
  "message": "Test Alert",
  "provider": "twilio"
}
```

---

## 7. Operations & Usage

### CLI Commands

**Wrappers (Recommended)**:
*   `./monitor/run_monitor.sh`: Runs the monitor.
*   `./run_api.sh`: Runs the API server.

**Manual Execution**:
```bash
# Run Monitor Once (Test)
python monitor/monitor.py --config config.json --once

# Run API
uvicorn api.main:app --host 0.0.0.0 --port 8000
```

### Workflows

**Full Setup Workflow**:
1.  **Register Host**: `POST /hosts` with SSH details.
2.  **Add Services**: `POST /services` for each systemd unit.
3.  **Generate Config**: `GET /config/download` -> Save to `monitor/config/config.json`.
4.  **Start Monitor**: `systemctl start svcctl-monitor`.

### Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Module not found** | Use `./run_monitor.sh` or activate venv. |
| **MongoDB Connection Fail** | Check `.env` credentials and `mongod` status. |
| **SSH Auth Fail** | Verify `key_path` in config and permissions (600). |
| **No SMS** | Check `cooldown_minutes` and E.164 phone format. |

---

## 8. Future Roadmap (Firebase)

**Status**: Planned Integration.

The architecture is designed to support Firebase Cloud Messaging (FCM) for push notifications:

1.  **Integration Point**: `LoggerManager` will trigger FCM push on `service_down` events.
2.  **Auth**: Service Account JSON for server-side, JWT for client-side.
3.  **Data Flow**:
    *   Monitor detects failure -> Logs to DB (`sent_to_user: false`).
    *   Notification Service polls/subscribes -> Pushes to FCM.
    *   Mobile App receives alert.

---

## 9. WhatsApp Integration (WA-BOT)

The system integrates with a local WhatsApp microservice (`WA-BOT`) to send notifications.

### Setup

1.  **Navigate to WA-BOT**:
    ```bash
    cd ../WA-BOT
    ```
2.  **Install Dependencies**:
    ```bash
    npm install
    ```
3.  **Start the Service**:
    ```bash
    node index.js
    ```
    *   Scan the QR code if prompted.
    *   The service listens on `http://localhost:3000`.

### Configuration

In your notification config (via API), set `sms_provider` to `whatsapp`.

```json
{
  "service_name": "nginx",
  "host": "web-01",
  "sms_provider": "whatsapp",
  "contacts": [
    {
      "name": "Admin",
      "phone": "1234567890",
      "notify_on": ["service_down"]
    }
  ]
}
```

### Testing

You can test the integration using `curl`:

```bash
curl -X POST http://localhost:3000/send-message \
     -H "Content-Type: application/json" \
     -d '{"phone": "1234567890", "message": "Test from Monitor"}'
```
