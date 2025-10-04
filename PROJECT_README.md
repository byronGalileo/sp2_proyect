# Service Monitoring System with MongoDB Integration

Complete service monitoring solution with both traditional file logging and MongoDB structured data storage.

## 🏗️ Project Structure

```
proyecto/
├── monitor/                    # Service Monitor v2.0
│   ├── monitor.py             # Main monitor (modular version)
│   ├── monitor_legacy.py      # Original monitor (backup)
│   ├── run_monitor.sh         # Wrapper script (recommended)
│   ├── run_monitor.py         # Python wrapper
│   ├── core/                  # Modular components
│   │   ├── config_loader.py   # Configuration management
│   │   ├── service_checker.py # Service status & remediation
│   │   ├── logger_manager.py  # Unified logging
│   │   └── service_monitor.py # Main orchestrator
│   ├── config/
│   │   ├── config.json        # Active configuration
│   │   └── config.example.json # Example configuration
│   └── logs/
│       └── service_monitor.log # Traditional log file
├── port-check/                 # Port health checking
│   └── port_health_check.py
├── database/                   # MongoDB logging system
│   ├── models.py              # Data models
│   ├── connection.py          # MongoDB connection
│   ├── operations.py          # Database operations
│   ├── config.py              # DB configuration
│   └── example_usage.py       # Usage examples
├── venv/                       # Python virtual environment
├── check_mongodb_logs.py       # Quick log checker
├── run_database_example.sh     # Database demo wrapper
└── requirements_mongodb.txt    # Dependencies
```

## 🚀 Quick Start

### 1. Setup (First Time)
```bash
# Create virtual environment and install dependencies
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_mongodb.txt
```

### 2. Run Service Monitor
```bash
# Option A: Using wrapper (recommended)
cd monitor/
./run_monitor.sh --config config/config.json --once

# Option B: Continuous monitoring
./run_monitor.sh --config config/config.json

# Option C: Manual activation
source ../venv/bin/activate
python monitor.py --config config/config.json
```

### 3. Check MongoDB Logs
```bash
# View all services
python3 check_mongodb_logs.py

# View specific service
python3 check_mongodb_logs.py dbus.service
```

### 4. Database Demo
```bash
# Run full database demo
./run_database_example.sh
```

## 📊 Features

### Service Monitor v2.0
- ✅ **Modular Architecture**: Clean separation of concerns
- ✅ **Dual Logging**: Traditional files + MongoDB structured data
- ✅ **Multi-Service Support**: Local and SSH remote monitoring
- ✅ **Individual Intervals**: Per-service monitoring intervals
- ✅ **Auto Remediation**: Automatic service restart/start
- ✅ **Rich Metadata**: Detailed service information in logs
- ✅ **Event Tracking**: Separate events collection
- ✅ **Error Handling**: Comprehensive validation and error reporting

### MongoDB Integration
- ✅ **Structured Logs**: Searchable service monitoring data
- ✅ **Event Tracking**: Monitor starts/stops, remediations
- ✅ **Time-Series Data**: Historical service status tracking
- ✅ **Statistics**: Service health metrics and reporting
- ✅ **Batch Operations**: Efficient bulk log processing
- ✅ **Indexed Queries**: Fast searches by service, time, level

## 🔧 Configuration Examples

### Basic Local Service
```json
{
  "mongodb": {
    "enabled": true,
    "host": "localhost",
    "port": 27017,
    "database": "service_monitoring"
  },
  "targets": [
    {
      "name": "nginx-local",
      "method": "local",
      "service": "nginx.service",
      "interval_sec": 30,
      "recover_on_down": true,
      "recover_action": "restart"
    }
  ]
}
```

### Remote SSH Service
```json
{
  "targets": [
    {
      "name": "db-server",
      "method": "ssh",
      "host": "10.0.0.100",
      "service": "postgresql.service",
      "ssh": {
        "user": "ubuntu",
        "port": 22
      },
      "interval_sec": 60,
      "use_sudo": true
    }
  ]
}
```

## 📈 MongoDB Data Examples

### Service Log Entry
```json
{
  "service_name": "nginx",
  "service_type": "local",
  "host": "web-server",
  "log_level": "INFO",
  "message": "status=active active=True",
  "timestamp": "2025-09-26T07:15:30Z",
  "status": "active",
  "metadata": {
    "method": "local",
    "interval_sec": 30
  },
  "tags": ["nginx-local", "status_check"],
  "date": "2025-09-26",
  "service_key": "web-server:nginx"
}
```

### Event Entry
```json
{
  "service_name": "nginx",
  "event_type": "service_remediation",
  "description": "Attempted restart on nginx: Success",
  "timestamp": "2025-09-26T07:15:30Z",
  "severity": "INFO",
  "metadata": {
    "action": "restart",
    "success": true,
    "return_code": 0
  }
}
```

## 🔍 Querying MongoDB

### Using Python API
```python
from database import log_operations

# Get recent logs
logs = log_operations.get_recent_logs("nginx", hours=24)

# Get error logs
errors = log_operations.get_error_logs(hours=24)

# Service statistics
stats = log_operations.get_service_statistics("nginx", hours=24)

# Custom queries
filtered = log_operations.get_logs(
    service_name="nginx",
    log_level=LogLevel.ERROR,
    start_time=datetime.now() - timedelta(hours=1)
)
```

### Using Command Line
```bash
# Quick overview
python3 check_mongodb_logs.py

# Specific service
python3 check_mongodb_logs.py nginx

# Help
python3 check_mongodb_logs.py --help
```

## 🛠️ Available Wrappers

All wrappers automatically handle virtual environment activation:

| Script | Purpose | Usage |
|--------|---------|-------|
| `monitor/run_monitor.sh` | Service monitor (bash) | `./run_monitor.sh --config config.json` |
| `monitor/run_monitor.py` | Service monitor (python) | `python3 run_monitor.py --config config.json` |
| `run_database_example.sh` | Database demo | `./run_database_example.sh` |
| `check_mongodb_logs.py` | Quick log viewer | `python3 check_mongodb_logs.py [service]` |

## 📊 Current Setup

Your current configuration monitors:
- **dbus.service** (local, 10s interval) - ✅ Active
- **mysql.service** (SSH remote) - ⏸️ Disabled

MongoDB is enabled and storing all monitoring data with full search capabilities.

## 🔧 Troubleshooting

### Virtual Environment Issues
```bash
# Use wrapper scripts - they handle venv automatically
./run_monitor.sh --config config.json

# Or activate manually
source venv/bin/activate
```

### MongoDB Connection
```bash
# Check status
systemctl status mongod

# Test connection
python3 check_mongodb_logs.py
```

### Dependencies
```bash
# Reinstall if needed
source venv/bin/activate
pip install -r requirements_mongodb.txt
```

## 🎯 Benefits

1. **Scalability**: MongoDB storage for historical data analysis
2. **Flexibility**: Traditional file logs + structured data
3. **Searchability**: Rich queries on service monitoring data
4. **Modularity**: Clean, maintainable codebase
5. **Reliability**: Comprehensive error handling and validation
6. **Usability**: Multiple wrapper scripts for easy execution