# Service Monitor v2.0 - Usage Guide

## 🚀 Quick Start

You have **3 ways** to run the service monitor:

### Option 1: Bash Wrapper (Recommended)
```bash
cd monitor/
./run_monitor.sh --config config/config.json --once
./run_monitor.sh --config config/config.json  # continuous
```

### Option 2: Python Wrapper
```bash
cd monitor/
python3 run_monitor.py --config config/config.json --once
python3 run_monitor.py --config config/config.json  # continuous
```

### Option 3: Manual Virtual Environment
```bash
source venv/bin/activate
cd monitor/
python monitor.py --config config/config.json --once
```

## 📋 Command Options

```bash
--config CONFIG_FILE    # Path to JSON configuration file (required)
--once                  # Run once and exit (optional)
--create-example        # Generate example config and exit
--version              # Show version information
```

## ⚙️ Configuration

### Current Active Config
Your `config/config.json` is set up with:
- **MongoDB logging enabled** (localhost:27017)
- **1 local test target** (dbus.service) - active
- **1 SSH target** (jeju-my-sql) - disabled

### Generate New Config
```bash
./run_monitor.sh --config new-config.json --create-example
```

### Config Structure
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
      "name": "service-name",
      "method": "local|ssh",
      "service": "service-name.service",
      "interval_sec": 30,
      "active": true
    }
  ]
}
```

## 📊 Viewing Logs

### Traditional File Logs
```bash
tail -f logs/service_monitor.log
```

### MongoDB Logs
```bash
source ../venv/bin/activate
python -c "
from database import log_operations
logs = log_operations.get_recent_logs('dbus', hours=1)
for log in logs[:5]:
    print(f'{log[\"timestamp\"]} - {log[\"message\"]}')
"
```

## 🔧 Troubleshooting

### "Module not found" errors
- Use the wrapper scripts (run_monitor.sh or run_monitor.py)
- They automatically handle virtual environment activation

### MongoDB connection issues
```bash
# Check MongoDB status
systemctl status mongod

# Test connection
./run_monitor.sh --config config/config.json --once
# Look for "MongoDB logging enabled" in output
```

### Configuration errors
```bash
# Generate fresh example config
./run_monitor.sh --config test.json --create-example
# Compare with your config file
```

## 🎯 Examples

### Monitor local services every 30 seconds
```json
{
  "targets": [
    {
      "name": "nginx-local",
      "method": "local",
      "service": "nginx.service",
      "interval_sec": 30,
      "recover_on_down": true
    }
  ]
}
```

### Monitor remote service via SSH
```json
{
  "targets": [
    {
      "name": "database-server",
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