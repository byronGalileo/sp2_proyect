# SP2 Project - Quick Reference Guide

## System at a Glance

**Type**: Python-based service monitoring system with REST API
**Framework**: FastAPI + MongoDB
**Purpose**: Monitor Linux services, auto-recover failures, send notifications
**Status**: Production-ready for core monitoring; Firebase integration pending

---

## Quick Architecture Overview

```
┌────────────────────────────────────────────────────┐
│          Monitor Process (systemd/standalone)      │
│  • Checks service status via systemctl/SSH         │
│  • Auto-restarts failed services                   │
│  • Logs to file + MongoDB                          │
└────────────────────┬───────────────────────────────┘
                     │
                     ↓
         ┌───────────────────────────┐
         │  MongoDB Atlas Database   │
         │ (Cloud-hosted)            │
         │ Collections:              │
         │ • logs (service checks)   │
         │ • events (important)      │
         │ • hosts (servers)         │
         │ • services (monitoring)   │
         │ • monitoring_history      │
         └────────────┬──────────────┘
                      │
                      ↓
         ┌──────────────────────────┐
         │  FastAPI REST Server     │
         │  (Port 8000)             │
         │                          │
         │ Endpoints:               │
         │ • /health                │
         │ • /logs, /stats          │
         │ • /hosts, /services      │
         │ • /monitoring/control    │
         │ • /config/generate       │
         └──────────────────────────┘
```

---

## Directory Structure (Key Files)

```
sp2_proyect/
├── api/
│   ├── main.py                 # FastAPI app definition
│   └── routers.py              # REST endpoints (900+ lines)
│
├── database/
│   ├── connection.py           # MongoDB connection & indexing
│   ├── operations.py           # Log CRUD operations
│   ├── host_operations.py      # Host management
│   ├── service_operations.py   # Service management
│   ├── monitoring_models.py    # Host, Service, History models
│   └── config.py               # MongoDB configuration
│
├── monitor/
│   ├── monitor.py              # Main monitoring script
│   ├── core/
│   │   ├── config_loader.py    # Parse config.json
│   │   ├── service_checker.py  # Check service status
│   │   ├── service_monitor.py  # Orchestrator
│   │   └── logger_manager.py   # Dual logging (file+DB)
│   ├── config/
│   │   └── config.example.json # Configuration template
│   ├── logs/                   # service_monitor.log
│   ├── run_monitor.sh          # Bash wrapper
│   └── svcctl-monitor.service  # Systemd unit file
│
├── .env                        # Environment variables
├── requirements_mongodb.txt    # Dependencies
└── run_api.sh                  # API startup script
```

---

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Language** | Python | 3.13 |
| **API Framework** | FastAPI | 0.103.2+ |
| **Server** | Uvicorn | 0.22.0+ |
| **Database** | MongoDB Atlas | Cloud |
| **DB Driver** | PyMongo | 4.7.3+ |
| **Validation** | Pydantic | 1.10.24+ |
| **Monitoring** | psutil | 5.9.0+ |

---

## Starting the Services

### Method 1: Monitor via Systemd
```bash
# Install the systemd service
sudo cp monitor/svcctl-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable svcctl-monitor.service
sudo systemctl start svcctl-monitor.service

# Check status
sudo systemctl status svcctl-monitor.service
```

### Method 2: Monitor Standalone
```bash
python monitor/monitor.py --config monitor/config/config.example.json
```

### Method 3: API Server
```bash
./run_api.sh 0.0.0.0 8000

# Or manually:
source venv/bin/activate
cd api/
python main.py --host 0.0.0.0 --port 8000
```

### Method 4: Control Monitor via API
```bash
# Start
curl -X POST http://localhost:8000/monitoring/start/config.local

# Stop
curl -X POST http://localhost:8000/monitoring/stop/config.local

# Check status
curl http://localhost:8000/monitoring/status
```

---

## Key Features

### Service Monitoring
- Local service checks (via systemctl)
- Remote service checks (via SSH)
- Configurable check intervals per service
- Automatic service recovery on failure
- SSH key and password authentication support

### Logging Architecture
- **File Logging**: `monitor/logs/service_monitor.log` (2MB rolling)
- **Database Logging**: MongoDB `logs` and `events` collections
- **Query Capability**: Rich filtering by service, time, level, host

### API Capabilities
- Create/manage hosts and services
- Query monitoring logs and statistics
- Generate config.json from database
- Control monitor processes (start/stop/restart)
- Dashboard summaries and alerts

### Configuration
- JSON-based monitor configuration
- Environment variable overrides
- Per-service monitoring intervals
- Per-service recovery actions (restart, reload, start, stop)

---

## Database Collections

### logs
Service check results with monitoring data
- Indexed by: timestamp, service_name, log_level, sent_to_user
- Contains: status, error messages, metadata
- **For Firebase**: Pull from `sent_to_user: false` to send notifications

### events
Important system events (startup, remediation, etc.)
- Types: status_check, service_remediation, monitor_start, monitor_stop
- Contains: severity, description, metadata

### hosts
Server/host configuration
- Fields: hostname, ip_address, environment, region, ssh_config
- Used for: SSH authentication to remote servers

### services
Service monitoring configuration
- Fields: service_name, host_id, monitoring intervals, recovery settings
- Links to hosts via host_id

### monitoring_history
Historical check results (auto-expires after 30 days)
- Tracks: service status over time, check results, metrics
- Used for: Uptime calculations, trend analysis

---

## API Endpoints Quick Reference

### Health & Stats
```
GET  /health                      # Database connection health
GET  /stats                       # Overall statistics
GET  /stats/{service_name}        # Per-service statistics
```

### Log Management
```
GET  /logs                        # Query logs with filters
GET  /logs/unsent                 # Logs awaiting notification
POST /logs/mark-sent              # Mark as delivered
```

### Host Management
```
POST /hosts                       # Create host
GET  /hosts                       # List hosts
GET  /hosts/{host_id}             # Get host details
PUT  /hosts/{host_id}             # Update host
DELETE /hosts/{host_id}           # Delete host
```

### Service Management
```
POST /services                    # Create service
GET  /services                    # List services
GET  /services/{service_id}       # Get service details
PUT  /services/{service_id}       # Update service
DELETE /services/{service_id}     # Delete service
```

### Configuration
```
GET  /config/generate/{host_id}   # Generate config.json
GET  /config/download/{host_id}   # Download config as file
```

### Monitor Control
```
GET  /monitoring/status           # All monitors status
GET  /monitoring/status/{name}    # Specific monitor status
POST /monitoring/start/{name}     # Start monitor
POST /monitoring/stop/{name}      # Stop monitor
POST /monitoring/restart/{name}   # Restart monitor
GET  /monitoring/configs          # List available configs
```

---

## Environment Variables (.env)

```bash
# MongoDB Connection (Atlas)
MONGO_HOST=clusterib.vq6e3jr.mongodb.net
MONGO_USERNAME=your_username
MONGO_PASSWORD=your_password
MONGO_CLUSTER=ClusterIB

# Database
MONGO_DB_NAME=service_monitoring
MONGO_LOGS_COLLECTION=logs
MONGO_EVENTS_COLLECTION=events

# Security (planned JWT auth)
SECRET_KEY=your_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

---

## Configuration File Format (config.json)

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
      "name": "web-nginx",
      "service": "nginx.service",
      "method": "ssh",
      "host": "192.168.1.100",
      "active": true,
      "interval_sec": 60,
      "timeout_sec": 30,
      "recover_on_down": true,
      "recover_action": "restart",
      "use_sudo": true,
      "ssh": {
        "user": "ubuntu",
        "port": 22
      }
    }
  ]
}
```

---

## Common Tasks

### Run a Single Monitoring Check
```bash
python monitor/monitor.py --config config.json --once
```

### Query Recent Errors
```bash
curl "http://localhost:8000/logs?log_level=ERROR&hours=24"
```

### Get Services Needing Attention
```bash
curl http://localhost:8000/services/attention/needed
```

### Create a New Service to Monitor
```bash
curl -X POST http://localhost:8000/services \
  -H "Content-Type: application/json" \
  -d '{
    "host_id": "web-server-1",
    "service_name": "nginx.service",
    "service_type": "nginx",
    "monitoring": {"enabled": true, "interval_sec": 60},
    "recovery": {"recover_on_down": true, "recover_action": "restart"}
  }'
```

### Generate Config from Database
```bash
curl "http://localhost:8000/config/download/web-server-1" \
  -o config.web-server-1.json
```

### Check All Running Monitors
```bash
curl http://localhost:8000/monitoring/status
```

---

## Logging Locations

### File Logs
- Location: `monitor/logs/service_monitor.log`
- Format: `%(asctime)s %(levelname)s %(message)s`
- Rotation: 2MB per file, 5 backup files

### Database Logs
- Collection: `service_monitoring.logs`
- Query example:
  ```python
  from database import log_operations
  logs = log_operations.get_recent_logs("nginx.service", hours=24)
  ```

### API Logs
- Printed to console when running in development
- Can be captured to file with systemd

---

## Authentication Status

**Current**: None (open API)
**Planned**: JWT tokens + API keys
**Recommended for Firebase**: Service account authentication + device token validation

---

## Firebase Integration Readiness

### Already Available
✅ Event logging system (perfect source for notifications)
✅ `sent_to_user` field in logs (for tracking delivery)
✅ Structured event types (status_check, remediation, etc.)
✅ REST API infrastructure
✅ MongoDB for device token storage

### Needs to be Added
❌ Firebase Admin SDK
❌ Device token management endpoints
❌ Notification sending logic
❌ Device subscription filtering
❌ FCM error handling and retry

### Estimated Effort
- Phase 1 (Foundation): 2-3 days
- Phase 2 (Integration): 2-3 days
- Phase 3 (Testing): 2-3 days
- Phase 4 (Production): 3-5 days
**Total**: 2-3 weeks for full implementation

---

## Performance Characteristics

### Database
- Concurrent connections: Up to 50 (configurable)
- Query performance: <100ms for most queries (with indexes)
- TTL auto-cleanup: 30 days for monitoring_history

### Monitor
- CPU: Minimal (1-5% per service checked)
- Memory: ~50-100MB base + per-service overhead
- Network: SSH connections cached/reused

### API
- Requests/second: 100+ (single instance)
- Response time: <200ms for typical endpoints
- Memory: ~100-150MB running

---

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Monitor won't start | Check .env MongoDB credentials |
| API connection refused | Verify port 8000 is available |
| Services not appearing | Ensure host exists before creating services |
| Empty logs in MongoDB | Check if MongoDB logging enabled in config |
| SSH auth failures | Verify SSH key path and permissions |
| Slow queries | Check database indexes created |

---

## Useful Commands

```bash
# Check Python dependencies
pip list | grep -E 'fastapi|pymongo|pydantic'

# Verify MongoDB connection
python -c "from database import mongo_connection; print(mongo_connection.health_check())"

# View recent logs
tail -f monitor/logs/service_monitor.log

# Check systemd service status
systemctl status svcctl-monitor.service

# Restart API
pkill -f "python main.py"
./run_api.sh 0.0.0.0 8000

# Query logs from MongoDB
python
>>> from database import log_operations
>>> logs = log_operations.get_unsent_logs(limit=10)
>>> for log in logs: print(log['message'])
```

---

## Document Map

- **ARCHITECTURE_COMPREHENSIVE_ANALYSIS.md** - Detailed architecture (14 sections)
- **QUICK_REFERENCE_GUIDE.md** - This file (quick start)
- **API_DOCUMENTATION.md** - API endpoint details
- **PROJECT_README.md** - Project overview
- **IMPLEMENTATION_SUMMARY.md** - Feature summary

---

## Next Steps for Firebase Integration

1. Read ARCHITECTURE_COMPREHENSIVE_ANALYSIS.md sections 4-9
2. Install firebase-admin: `pip install firebase-admin`
3. Create new `database/notifications.py` module
4. Add hooks to `monitor/core/logger_manager.py`
5. Create `/notifications/*` endpoints in `api/routers.py`
6. Test with sample device tokens

---

## Support References

- FastAPI Docs: https://fastapi.tiangolo.com/
- MongoDB Docs: https://docs.mongodb.com/
- Firebase Docs: https://firebase.google.com/docs
- PyMongo Docs: https://pymongo.readthedocs.io/
