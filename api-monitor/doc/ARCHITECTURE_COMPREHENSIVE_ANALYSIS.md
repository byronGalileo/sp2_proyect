# SP2 Project - Comprehensive Architecture Analysis
## Firebase Push Notifications Implementation Guide

---

## EXECUTIVE SUMMARY

The SP2 Project is a **comprehensive Python-based service monitoring system** built with:
- **Backend**: FastAPI (Python 3.13)
- **Database**: MongoDB (cloud-hosted on MongoDB Atlas)
- **Architecture**: Modular microservices with REST API, event-driven monitoring, and structured logging
- **Deployment**: Systemd-based service management with optional API server

This document provides a detailed architectural overview to support Firebase Cloud Messaging (FCM) integration for push notifications.

---

## 1. PROJECT STRUCTURE AND TECHNOLOGY STACK

### 1.1 Core Components

```
sp2_proyect/
├── api/                      # FastAPI REST API
│   ├── main.py              # FastAPI application (v2.0.0)
│   ├── routers.py           # API routers (hosts, services, config, monitoring)
│   └── __init__.py
│
├── database/                # MongoDB Integration
│   ├── models.py            # Legacy log/event models
│   ├── monitoring_models.py # Host/Service/MonitoringHistory models
│   ├── operations.py        # Log operations
│   ├── host_operations.py   # CRUD for hosts
│   ├── service_operations.py# CRUD for services
│   ├── monitoring_operations.py # History and metrics
│   ├── connection.py        # MongoDB connection management
│   └── config.py            # Configuration loader
│
├── monitor/                 # Service Monitoring Engine
│   ├── monitor.py           # Main orchestrator
│   ├── run_monitor.py       # Python wrapper
│   ├── run_monitor.sh       # Bash wrapper
│   ├── core/
│   │   ├── config_loader.py    # YAML/JSON config parsing
│   │   ├── service_checker.py  # Service status checking
│   │   ├── service_monitor.py  # Monitoring orchestrator
│   │   └── logger_manager.py   # Unified logging
│   ├── config/
│   │   └── config.example.json # Configuration template
│   ├── logs/                    # Traditional file logs
│   └── svcctl-monitor.service   # Systemd service unit
│
├── port-check/              # Port health checking utility
│
├── requirements_mongodb.txt # Python dependencies
├── .env                     # Environment configuration
└── API_DOCUMENTATION.md    # API reference

```

### 1.2 Technology Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Language** | Python | 3.13 | Core implementation |
| **API Framework** | FastAPI | 0.103.2+ | REST API server |
| **ASGI Server** | Uvicorn | 0.22.0+ | ASGI application server |
| **Database** | MongoDB | Cloud (Atlas) | Data persistence |
| **MongoDB Driver** | PyMongo | 4.7.3+ | Database client |
| **Data Validation** | Pydantic | 1.10.24+ | Request/response models |
| **Process Management** | psutil | 5.9.0+ | Process monitoring |
| **Async MongoDB** | Motor | 3.4.0+ | Async database operations (optional) |
| **Logging** | colorlog | 6.9.0+ | Colored console output |
| **Environment** | python-dotenv | 0.21.1+ | Configuration management |
| **Service Management** | systemd | Native | Service lifecycle management |

### 1.3 Python Environment

```bash
# Virtual environment location
venv/lib/python3.13/site-packages/

# Key packages installed
fastapi, uvicorn, pydantic, pymongo, dnspython, psutil, 
python-dotenv, colorlog, motor
```

---

## 2. SERVICES AND SYSTEMD INTEGRATION

### 2.1 Systemd Service Unit

**File**: `/Users/josebarreno/Documents/Development_REPO/Proyecto-SPII/sp2_proyect/monitor/svcctl-monitor.service`

```ini
[Unit]
Description=Service Monitor (systemd watchdog)
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/service-monitor
ExecStart=/usr/bin/python3 /opt/service-monitor/monitor.py --config /opt/service-monitor/config.json
Restart=on-failure
RestartSec=5
User=svcctl
Group=svcctl
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

### 2.2 Service Control

The system supports two deployment models:

#### **Model 1: Direct Systemd Service** (Traditional)
```bash
# Start the monitor as a system service
sudo systemctl start svcctl-monitor.service
sudo systemctl status svcctl-monitor.service
```

#### **Model 2: API-Based Service Control** (Modern)
The FastAPI application includes `/monitoring` endpoints to manage monitor processes programmatically:

```bash
# Start monitor via API
POST /monitoring/start/{config_name}

# Stop monitor via API
POST /monitoring/stop/{config_name}

# Get monitor status
GET /monitoring/status/{config_name}

# List available configurations
GET /monitoring/configs
```

### 2.3 Service Control Implementation

**File**: `api/routers.py` (lines 818-1182)

```python
class MonitorProcessInfo:
    """Tracks running monitor processes"""
    - config_name: str
    - config_path: str
    - process: subprocess.Popen
    - start_time: datetime
    - restart_count: int

# Global process management
monitor_processes = {}  # {config_name: process_info}
process_lock = Lock()  # Thread-safe operations
```

**Key Features**:
- Spawns monitor processes with `subprocess.Popen()`
- Graceful shutdown with signal handling
- Process group management (`os.setsid`)
- Real-time process monitoring (PID, memory, CPU)
- Automatic restart on failure

---

## 3. LOGGING AND LOG MANAGEMENT

### 3.1 Dual Logging Architecture

The system implements a **hybrid logging approach**:

#### **Traditional File Logging**
- **Location**: `monitor/logs/service_monitor.log`
- **Handler**: `RotatingFileHandler` (2MB max, 5 backup files)
- **Format**: `%(asctime)s %(levelname)s %(message)s`
- **Levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL

#### **MongoDB Structured Logging**
- **Collections**: `logs`, `events`, `monitoring_history`
- **Query**: Rich filtering by service, time, level, host
- **Retention**: TTL-based auto-expiration for history (30 days)

### 3.2 Log Management API Endpoints

```
GET  /logs                          # Query logs with filters
GET  /logs/unsent                   # Get unsent logs (push notification queue)
POST /logs/mark-sent                # Mark logs as delivered
GET  /stats                         # Overall statistics
GET  /stats/{service_name}          # Per-service statistics
```

### 3.3 LoggerManager Implementation

**File**: `monitor/core/logger_manager.py`

```python
class LoggerManager:
    """Unified logging with MongoDB integration"""
    
    def __init__(self, log_path: str, mongodb_config: Optional[Dict]):
        # Traditional file logging
        self.logger = self._setup_file_logger()
        
        # MongoDB logging (if enabled)
        if mongodb_config.get("enabled"):
            self._setup_mongodb()
    
    def log_service_status(self, target_name, service_name, status, is_active, ...):
        # Logs to both file and MongoDB
        
    def log_remediation_attempt(self, target_name, service_name, action, success, ...):
        # Tracks auto-recovery actions
        
    def log_monitor_start/stop(self, ...):
        # Event logging for monitoring lifecycle
```

### 3.4 Log Collection Structures

#### **logs Collection**
```json
{
  "_id": ObjectId,
  "service_name": "nginx.service",
  "service_type": "local|remote",
  "host": "web-server",
  "log_level": "INFO|WARNING|ERROR",
  "message": "Service status check result",
  "timestamp": datetime,
  "status": "active|inactive|failed",
  "metadata": {
    "method": "local|ssh",
    "interval_sec": 30,
    "return_code": 0
  },
  "tags": ["tag1", "tag2"],
  "sent_to_user": false,  // ← For push notification tracking
  "date": "2025-11-07",
  "service_key": "web-server:nginx.service"
}
```

#### **events Collection**
```json
{
  "_id": ObjectId,
  "service_name": "nginx.service",
  "event_type": "status_check|remediation|monitor_start",
  "description": "Event description",
  "host": "web-server",
  "severity": "INFO|WARNING|ERROR",
  "timestamp": datetime,
  "metadata": {
    "action": "restart",
    "success": true,
    "return_code": 0
  }
}
```

### 3.5 Log Queries and Indexes

**Indexes created** (in connection.py):
```python
logs_collection.create_index("timestamp")
logs_collection.create_index("service_name")
logs_collection.create_index("log_level")
logs_collection.create_index([("service_name", 1), ("timestamp", -1)])
logs_collection.create_index([("date", 1), ("service_name", 1)])
logs_collection.create_index("sent_to_user")  # ← For push queries
```

---

## 4. AUTHENTICATION AND AUTHORIZATION

### 4.1 Current State

**Status**: ⚠️ **NOT IMPLEMENTED**

The current API has:
- ✅ CORS enabled (all origins)
- ❌ No authentication mechanism
- ❌ No API key validation
- ❌ No JWT tokens
- ❌ No role-based access control

**Configuration**:
```python
# api/main.py (lines 56-63)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ← No origin restriction
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 4.2 Environment Variables for Potential Auth

**File**: `.env`
```
SECRET_KEY=iUM6ra52FDvXHGg4gqMzbXXPKynEMMLOguXLDgJ7
SECRET_ENCODE=LRBeyNycg3M-Z8ZTHWBqfBtS-pc7Zu1pySlbhQxXvsQ=
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

These variables suggest **JWT-based authentication was planned** but not yet implemented.

### 4.3 Recommendations for Push Notification Auth

For Firebase integration, implement:

1. **Server-to-Server Authentication**:
   - Service account JSON for Firebase Admin SDK
   - Store credentials in environment variables

2. **Client Authentication** (Optional):
   - JWT tokens for API endpoints
   - API keys for client apps

3. **Device Token Management**:
   - Store FCM tokens in database
   - Validate tokens before sending notifications

---

## 5. NOTIFICATION AND EVENT HANDLING SYSTEMS

### 5.1 Current Event Handling

The system has **structured event logging** but NOT a notification system:

```
Monitor Execution Flow
    ↓
Status Check Performed
    ↓
Log Entry Created
    ├→ File: service_monitor.log
    └→ MongoDB: logs collection
    
Service Not Active?
    ↓
Remediation Attempted
    ↓
Event Created
    └→ MongoDB: events collection
```

### 5.2 Event Types Tracked

1. **status_check**: Service status verification
2. **service_remediation**: Auto-recovery actions
3. **monitor_start**: Monitor startup
4. **monitor_stop**: Monitor shutdown

### 5.3 Available Event Data for Notifications

```python
# Service status checks
{
    "service_name": "nginx.service",
    "status": "active|inactive|failed",
    "timestamp": "2025-11-07T10:30:00Z",
    "host": "web-server",
    "log_level": "INFO|ERROR"
}

# Remediation attempts
{
    "event_type": "service_remediation",
    "service_name": "nginx.service",
    "action": "restart|reload|start|stop",
    "success": true|false,
    "return_code": 0,
    "timestamp": "2025-11-07T10:30:00Z"
}
```

### 5.4 Integration Points for Push Notifications

**Recommended Integration Points**:

```
1. After log_service_status() in logger_manager.py
   → Check if service down → Send FCM notification
   
2. After log_remediation_attempt()
   → Log remediation result → Send FCM notification
   
3. Via new POST /logs/unsent/notify endpoint
   → Bulk send notifications for all unsent logs
   
4. Via service health webhook
   → Real-time alert on critical state change
```

---

## 6. CONFIGURATION MANAGEMENT

### 6.1 Environment Configuration

**File**: `.env`
```bash
# MongoDB Connection (Atlas)
MONGO_HOST=clusterib.vq6e3jr.mongodb.net
MONGO_USERNAME=joseivanbarreno_db_user
MONGO_PASSWORD=Xl31sNXgteIvNQrY
MONGO_CLUSTER=ClusterIB

# Database Configuration
DATABASE_URL=mysql+pymysql://ivan:...@localhost:3306/core_management_system

# Security (for future JWT implementation)
SECRET_KEY=iUM6ra52FDvXHGg4gqMzbXXPKynEMMLOguXLDgJ7
SECRET_ENCODE=LRBeyNycg3M-Z8ZTHWBqfBtS-pc7Zu1pySlbhQxXvsQ=
ALGORITHM=HS256
```

### 6.2 Monitor Configuration (JSON)

**File**: `monitor/config/config.example.json`

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
      "name": "local-prometheus",
      "service": "prometheus.service",
      "method": "local|ssh",
      "active": true,
      "interval_sec": 30,
      "recover_on_down": true,
      "recover_action": "restart|reload|start|stop",
      "use_sudo": false,
      "timeout_sec": 30,
      "ssh": {
        "user": "ubuntu",
        "port": 22
      }
    }
  ]
}
```

### 6.3 Configuration Management Classes

**ConfigLoader** (`monitor/core/config_loader.py`):
- Parses JSON configuration files
- Validates targets and settings
- Provides typed access to configuration
- Supports environment variable overrides

**MongoConfig** (`database/config.py`):
- Builds MongoDB connection strings
- Manages database and collection names
- Supports both local and cloud (Atlas) connections

### 6.4 Dynamic Configuration Features

The API supports dynamic configuration generation:

```
Database (Hosts + Services)
    ↓
/config/generate endpoint
    ↓
config.json (in monitor/config/)
    ↓
Monitor loads and executes
    ↓
Results logged to MongoDB
```

---

## 7. DEPENDENCIES AND PACKAGE MANAGEMENT

### 7.1 Python Dependencies

**File**: `requirements_mongodb.txt`

```
pymongo>=4.7.3              # MongoDB driver
dnspython>=2.3.0            # DNS resolution for MongoDB Atlas
motor>=3.4.0                # Async MongoDB (optional)
python-dotenv>=0.21.1       # Environment variable management
colorlog>=6.9.0             # Colored logging output
fastapi>=0.103.2            # Web framework
uvicorn[standard]>=0.22.0   # ASGI server
pydantic>=1.10.24           # Data validation
psutil>=5.9.0               # Process management
```

### 7.2 Virtual Environment Setup

```bash
# Location
/Users/josebarreno/Documents/Development_REPO/Proyecto-SPII/sp2_proyect/venv/

# Python version
python3.13

# Setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_mongodb.txt

# Activation scripts
venv/bin/activate
venv/bin/activate.csh
venv/bin/activate.fish
```

### 7.3 Dependency Graph for Firebase Integration

```
fastapi ─┬─ starlette
         ├─ pydantic
         └─ uvicorn

firebase-admin ─┬─ google-cloud-messaging
                ├─ google-auth
                ├─ google-cloud-storage
                └─ requests

pymongo ─┬─ dnspython
         └─ bson

Final stack:
  FastAPI + Firebase Admin SDK + PyMongo
```

---

## 8. DATABASE SCHEMA AND COLLECTIONS

### 8.1 Collections Overview

| Collection | Purpose | Auto-Expiry | Indexes |
|-----------|---------|-------------|---------|
| **logs** | Service check results | None | service_name, timestamp, log_level |
| **events** | Important events | None | service_name, event_type, timestamp |
| **hosts** | Server configurations | None | host_id, environment, region |
| **services** | Service configurations | None | service_id, host_id, service_type |
| **monitoring_history** | Check history | 30 days (TTL) | service_id, host_id, timestamp |

### 8.2 Key Model Classes

**File**: `database/monitoring_models.py`

```python
class Host:
    host_id: str
    hostname: str
    ip_address: str
    environment: str
    region: str
    ssh_config: Dict
    status: HostStatus
    metadata: Dict
    created_at: datetime
    updated_at: datetime

class Service:
    service_id: str
    host_id: str
    service_name: str
    service_type: str
    monitoring_enabled: bool
    interval_sec: int
    recover_on_down: bool
    recover_action: RecoveryAction
    alerting_enabled: bool
    current_status: ServiceStatus
    last_check: datetime

class MonitoringHistory:
    service_id: str
    host_id: str
    timestamp: datetime
    status: ServiceStatus
    check_type: CheckType
    metrics: Dict
    error_details: str
    recovery_attempted: bool
    expires_at: datetime  # TTL field
```

### 8.3 Data Relationships

```
Hosts
  └─→ Services (host_id foreign key)
      └─→ MonitoringHistory (service_id foreign key)
      └─→ logs (service_name, host references)
      └─→ events (service_name references)
```

---

## 9. ARCHITECTURE FOR FIREBASE PUSH NOTIFICATIONS

### 9.1 Proposed Integration Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Monitoring System                        │
│  (monitor.py, service_checker.py, logger_manager.py)   │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
         ┌───────────────────────────┐
         │   MongoDB Logging         │
         │ (logs, events collections)│
         └────────────┬──────────────┘
                      │
         ┌────────────┴──────────────┐
         │                           │
         ↓                           ↓
    ┌──────────────┐         ┌────────────────────┐
    │ Traditional  │         │  Firebase Cloud    │
    │  File Logs   │         │   Messaging (FCM)  │
    │              │         │                    │
    │ service_     │         │ • Device tokens    │
    │ monitor.log  │         │ • Push messages    │
    │              │         │ • Notifications    │
    └──────────────┘         └────────────────────┘
                                     ↑
         ┌───────────────────────────┘
         │
         ↓
    ┌──────────────────────────┐
    │  Push Notification       │
    │  Service Module (NEW)    │
    │                          │
    │ • Firebase Admin SDK     │
    │ • Token management       │
    │ • Message formatting     │
    │ • Error handling         │
    └──────────────────────────┘
         ↑
         │
    ┌────┴──────────────────────┐
    │                           │
┌───┴──────────┐         ┌──────┴─────────┐
│   Logger     │         │   API          │
│   Manager    │         │   Endpoints    │
│              │         │                │
│ log_service_ │         │ POST /notify   │
│ status()     │         │ POST /mark-sent│
│ log_remediat │         │ GET /logs/unsent
│ ion_attempt()│         │                │
└──────────────┘         └────────────────┘
```

### 9.2 Key Integration Points

**Point 1: In LoggerManager.log_service_status()**
```python
def log_service_status(self, target_name, service_name, status, is_active, ...):
    # Existing file and MongoDB logging
    ...
    
    # NEW: Send push notification if service is down
    if not is_active and should_notify:
        push_service.notify_service_down(
            service_name=service_name,
            host=host,
            status=status,
            error=error
        )
```

**Point 2: In LoggerManager.log_remediation_attempt()**
```python
def log_remediation_attempt(self, target_name, service_name, action, success, ...):
    # Existing file and MongoDB logging
    ...
    
    # NEW: Notify about remediation result
    if not success:
        push_service.notify_remediation_failed(
            service_name=service_name,
            action=action,
            error=error_details
        )
```

**Point 3: New API Endpoint**
```python
@app.post("/logs/unsent/notify")
async def notify_unsent_logs(batch_size: int = 100):
    """Send push notifications for all unsent logs"""
    unsent = log_operations.get_unsent_logs(limit=batch_size)
    
    for log in unsent:
        push_service.send_notification(log)
    
    # Mark as sent after successful notification
    log_operations.mark_logs_as_sent([log["_id"] for log in unsent])
```

### 9.3 Database Changes Required

Add to logs collection:
```json
{
  "...existing fields...",
  "notification_sent": false,  // Track notification status
  "notification_sent_at": null,
  "notification_device_tokens": ["token1", "token2"],  // Target devices
  "notification_retries": 0,
  "notification_error": null
}
```

Add new collection for device management:
```
// devices collection
{
  "_id": ObjectId,
  "user_id": "user123",
  "device_token": "fcm_token...",
  "device_name": "iPhone 12",
  "platform": "ios|android|web",
  "subscribed_services": ["nginx", "mysql"],
  "subscribed_hosts": ["web-server", "db-server"],
  "created_at": datetime,
  "updated_at": datetime,
  "last_used": datetime,
  "active": true
}
```

### 9.4 Firebase Configuration

**Required additions to .env**:
```bash
# Firebase Cloud Messaging
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY_ID=private_key_id
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@...iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your_client_id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token

# FCM Configuration
FCM_RETRY_ATTEMPTS=3
FCM_RETRY_DELAY_SEC=5
FCM_BATCH_SIZE=500  # Messages per batch
FCM_TIMEOUT_SEC=30
```

---

## 10. API ENDPOINTS OVERVIEW

### 10.1 Monitoring Endpoints

```
GET    /                                    # Root info
GET    /health                              # Health check
GET    /stats                               # General statistics
GET    /stats/{service_name}                # Service statistics
GET    /services_summary                    # All services summary
```

### 10.2 Log Management Endpoints

```
GET    /logs                                # Query logs
GET    /logs/unsent                         # Unsent logs (for notifications)
POST   /logs/mark-sent                      # Mark as delivered
POST   /logs/unsent/notify                  # Send push notifications (NEW)
```

### 10.3 Host Management Endpoints

```
POST   /hosts                               # Create host
GET    /hosts                               # List hosts
GET    /hosts/{host_id}                     # Get specific host
PUT    /hosts/{host_id}                     # Update host
DELETE /hosts/{host_id}                     # Delete host
GET    /hosts/metadata/environments         # List environments
GET    /hosts/metadata/regions              # List regions
```

### 10.4 Service Management Endpoints

```
POST   /services                            # Create service
GET    /services                            # List services
GET    /services/{service_id}               # Get specific service
PUT    /services/{service_id}               # Update service
DELETE /services/{service_id}               # Delete service
GET    /services/dashboard/summary          # Dashboard summary
GET    /services/attention/needed           # Services needing attention
```

### 10.5 Configuration Endpoints

```
GET    /config/generate/{host_id}           # Generate config
GET    /config/download/{host_id}           # Download config
```

### 10.6 Monitor Control Endpoints

```
GET    /monitoring/status                   # All monitors status
GET    /monitoring/status/{config_name}     # Specific monitor status
POST   /monitoring/start/{config_name}      # Start monitor
POST   /monitoring/stop/{config_name}       # Stop monitor
POST   /monitoring/restart/{config_name}    # Restart monitor
POST   /monitoring/control                  # Control with action
GET    /monitoring/configs                  # List configs
```

### 10.7 NEW: Push Notification Endpoints (Proposed)

```
POST   /notifications/subscribe              # Subscribe device to notifications
POST   /notifications/unsubscribe            # Unsubscribe device
GET    /notifications/devices                # List devices
POST   /notifications/send                   # Send notification (admin)
POST   /logs/unsent/notify                  # Notify unsent logs
GET    /notifications/history/{device_token} # Notification history
```

---

## 11. STARTUP AND DEPLOYMENT

### 11.1 Service Startup Flow

```
1. System Boot
    ↓
2. Systemd loads svcctl-monitor.service
    ↓
3. ExecStart: python3 monitor.py --config /opt/service-monitor/config.json
    ↓
4. monitor.py initializes:
    - ConfigLoader.load() → loads JSON config
    - LoggerManager() → file + MongoDB logging
    - ServiceMonitor() → orchestrator
    ↓
5. Main loop: for each active target:
    - ServiceChecker.check_service_status()
    - LoggerManager.log_service_status()
    - If down: ServiceChecker.remediate_service()
    - Sleep interval_sec seconds
    ↓
6. Logs saved to:
    - monitor/logs/service_monitor.log
    - MongoDB: logs collection
    - MongoDB: events collection
```

### 11.2 API Startup Flow

```bash
./run_api.sh 0.0.0.0 8000
  ↓
Activates virtual environment
  ↓
Calls: python api/main.py --host 0.0.0.0 --port 8000
  ↓
FastAPI app initialization:
  - CORS middleware
  - Routers registration (hosts, services, config, monitoring)
  - Database connection
  ↓
Uvicorn ASGI server starts on 0.0.0.0:8000
  ↓
API ready for requests
```

### 11.3 Process Isolation

- **Monitor**: Runs as systemd service (User: svcctl, Group: svcctl)
- **API**: Runs as standalone process (Python process)
- **Database**: MongoDB Atlas (cloud-hosted)

### 11.4 File Permissions

```
svcctl-monitor.service:  644
monitor.py:             755
run_monitor.sh:         755
run_api.sh:             755
.env:                   600 (sensitive)
```

---

## 12. SUMMARY TABLE: ARCHITECTURE COMPONENTS

| Component | Technology | Purpose | Status |
|-----------|-----------|---------|--------|
| **Monitoring Engine** | Python (systemd) | Service health checks | ✅ Production |
| **REST API** | FastAPI + Uvicorn | Management & data access | ✅ Production |
| **Database** | MongoDB Atlas | Data persistence | ✅ Production |
| **Logging** | File + MongoDB | Event tracking | ✅ Production |
| **Process Control** | subprocess + psutil | Monitor lifecycle | ✅ Production |
| **Configuration** | JSON + Environment | System settings | ✅ Production |
| **Authentication** | - | API security | ❌ Planned |
| **Push Notifications** | - (Firebase ready) | User alerts | ❌ Planned |

---

## 13. FIREBASE PUSH NOTIFICATIONS IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Week 1-2)
- [ ] Install firebase-admin SDK
- [ ] Create Firebase project and service account
- [ ] Add Firebase credentials to .env
- [ ] Create PushNotificationService class
- [ ] Implement device token management (new collection)

### Phase 2: Integration (Week 2-3)
- [ ] Add notification hooks to LoggerManager
- [ ] Create new /notifications/* endpoints
- [ ] Implement notification database schema
- [ ] Add notification sent tracking to logs
- [ ] Create device subscription management

### Phase 3: Testing & Refinement (Week 3-4)
- [ ] Unit tests for notification sending
- [ ] Integration tests with Firebase
- [ ] Load testing (1000+ devices)
- [ ] Error handling and retry logic
- [ ] Notification history/audit logging

### Phase 4: Production (Week 4+)
- [ ] Deploy Firebase Admin SDK
- [ ] Monitor notification delivery rates
- [ ] Set up notification analytics
- [ ] User dashboard for notification preferences
- [ ] Multi-language message templates

---

## 14. KEY INSIGHTS FOR FIREBASE INTEGRATION

1. **Existing Infrastructure is Ready**:
   - MongoDB is cloud-hosted (easy to extend with device/notification collections)
   - Structured events already tracked (perfect source for notifications)
   - API endpoints ready for push notification management

2. **Integration Points are Clear**:
   - LoggerManager has perfect hooks for notifications
   - EventEntry model already captures alert-worthy events
   - sent_to_user field in logs is placeholder for push tracking

3. **Scalability Considerations**:
   - MongoDB TTL indexes ensure logs don't grow unbounded
   - Device token management needed (separate collection)
   - Batch sending for efficiency (Firebase allows 500 msgs/batch)
   - Retry logic for failed deliveries

4. **Security Requirements**:
   - Firebase service account credentials in secure environment
   - Device token validation before sending
   - Optional user authentication for /notifications endpoints
   - Rate limiting on notification sends

5. **Operational Requirements**:
   - Monitor FCM API quota and limits
   - Track delivery failures and bounces
   - Implement device token refresh mechanism
   - User-facing notification preferences management

---

## Conclusion

The SP2 Project has a well-architected, modular system that is **production-ready for Firebase integration**. The existing event logging, structured database, and RESTful API provide a solid foundation for implementing push notifications with minimal additional complexity.

The recommended approach is to:
1. Create a new `notifications.py` module in the database package
2. Add Firebase hooks in `LoggerManager`
3. Implement new `/notifications/*` endpoints
4. Extend the schema with device and notification_record collections

This integration would enhance the system's alerting capabilities while maintaining the existing clean separation of concerns.
