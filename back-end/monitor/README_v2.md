# Service Monitor v2.0 - Modular Architecture with MongoDB Integration

## 🚀 New Features

**Modular Architecture:**
- Separated into logical modules for better maintainability
- Clean separation of concerns (config, logging, service checking, monitoring)
- Improved error handling and validation

**MongoDB Integration:**
- Dual logging: traditional file logs + MongoDB structured storage
- Rich metadata and searchable logs
- Event tracking for significant monitoring events
- Backward compatible with existing file-based logging

**Enhanced Configuration:**
- Better validation and error messages
- Example configuration generation
- MongoDB settings integration

## 📁 Project Structure

```
monitor/
├── monitor.py              # Main entry point (v2.0)
├── monitor_legacy.py       # Original monitor (backup)
├── core/                   # Modular components
│   ├── __init__.py
│   ├── config_loader.py    # Configuration management
│   ├── service_checker.py  # Service status checking & remediation
│   ├── logger_manager.py   # Unified logging with MongoDB
│   └── service_monitor.py  # Main monitoring orchestrator
├── config/
│   ├── config.json         # Active configuration
│   └── config.example.json # Generated example
└── logs/
    └── service_monitor.log # Traditional log file
```

## 🔧 Usage

### Basic Commands

```bash
# Activate virtual environment
source ../venv/bin/activate

# Run once
python monitor.py --config config/config.json --once

# Run continuously
python monitor.py --config config/config.json

# Generate example config
python monitor.py --config any-path.json --create-example

# Show version
python monitor.py --version
```

### Configuration Format

```json
{
  "log_file": "logs/service_monitor.log",
  "log_level": "INFO",
  "mongodb": {
    "enabled": true,
    "host": "localhost",
    "port": 27017,
    "database": "service_monitoring",
    "username": "optional",
    "password": "optional"
  },
  "targets": [
    {
      "name": "local-service",
      "method": "local",
      "service": "nginx.service",
      "interval_sec": 30,
      "recover_on_down": true,
      "recover_action": "restart",
      "use_sudo": false,
      "active": true
    },
    {
      "name": "remote-service",
      "method": "ssh",
      "host": "10.0.0.10",
      "service": "mysql.service",
      "ssh": {
        "user": "ubuntu",
        "port": 22
      },
      "interval_sec": 60,
      "recover_on_down": true,
      "recover_action": "restart",
      "use_sudo": true,
      "active": true
    }
  ]
}
```

## 📊 MongoDB Integration

### What Gets Logged

**Service Logs:**
- Service status checks with detailed metadata
- Remediation attempts and results
- Configuration errors and system events

**Events:**
- Monitor start/stop events
- Service remediation events
- System alerts and notifications

### Querying MongoDB Logs

```python
from database import log_operations

# Get recent logs for a service
recent_logs = log_operations.get_recent_logs("nginx", hours=24)

# Get error logs
error_logs = log_operations.get_error_logs(hours=24)

# Get service statistics
stats = log_operations.get_service_statistics("nginx", hours=24)

# Query with filters
filtered_logs = log_operations.get_logs(
    service_name="nginx",
    log_level=LogLevel.ERROR,
    start_time=datetime.now() - timedelta(hours=1)
)
```

### MongoDB Collections

- `logs`: Structured service monitoring logs
- `events`: Significant monitoring events

## 🔍 Key Improvements from v1.x

1. **Modular Design**: Code split into focused, testable modules
2. **Better Error Handling**: Comprehensive validation and error reporting
3. **Dual Logging**: File + MongoDB for flexibility
4. **Enhanced Metadata**: Rich context in log entries
5. **Configuration Validation**: Better error messages and validation
6. **Event Tracking**: Separate collection for significant events
7. **Improved CLI**: Better user interface and help

## 🔄 Migration from v1.x

The new monitor is **backward compatible** with existing configurations. Simply:

1. Update your config to include MongoDB settings (optional)
2. Use the new `monitor.py` instead of the legacy version
3. Existing log files and formats remain unchanged

## 🛠 Dependencies

- **Python 3.8+**
- **pymongo**: MongoDB integration
- **dataclasses**: Configuration models (Python 3.7+ built-in)

## 🔧 Environment Variables (Optional)

For MongoDB configuration:
```bash
export MONGO_HOST=localhost
export MONGO_PORT=27017
export MONGO_USERNAME=your_user
export MONGO_PASSWORD=your_password
export MONGO_DB_NAME=service_monitoring
```

## 📈 Performance

- **Memory**: Minimal increase due to modular design
- **CPU**: Same as v1.x for monitoring logic
- **Storage**: MongoDB logs provide additional benefits without performance impact
- **Network**: No additional network overhead for local services

## 🐛 Troubleshooting

**MongoDB Connection Issues:**
```bash
# Check MongoDB status
systemctl status mongod

# Test connection
python -c "from database import log_operations; print('Connected!' if log_operations.connection.connect() else 'Failed!')"
```

**Configuration Errors:**
```bash
# Generate and compare with example
python monitor.py --config config.json --create-example
```

**Permission Issues:**
- Ensure proper systemctl permissions
- Check SSH key authentication for remote targets
- Review sudo configuration if using use_sudo option