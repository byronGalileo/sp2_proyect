#!/usr/bin/env python3
"""
Service Monitor v2.0 - Modular service monitoring with MongoDB integration

Features:
- Modular architecture with separate components
- MongoDB logging integration alongside traditional file logging
- Configurable monitoring intervals per service
- Local and SSH service monitoring
- Automatic service remediation
- Enhanced error handling and logging

Usage:
    python monitor.py --config config/config.json [--once]

Configuration:
    See config/config.example.json for configuration format
"""

import argparse
import sys
import os

# Add current directory to Python path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core import ConfigLoader, ServiceMonitor, LoggerManager

def create_example_config():
    """Create example configuration file"""
    config_path = "config/config.example.json"
    print(f"Creating example configuration at {config_path}")
    ConfigLoader.create_example_config(config_path)
    print("Example configuration created. Copy it to your actual config file and modify as needed.")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Service Monitor v2.0 - Modular service monitoring with MongoDB integration"
    )
    parser.add_argument(
        "--config",
        required=True,
        help="Path to configuration JSON file"
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run monitoring once and exit (no continuous loop)"
    )
    parser.add_argument(
        "--create-example",
        action="store_true",
        help="Create example configuration file and exit"
    )
    parser.add_argument(
        "--version",
        action="version",
        version="Service Monitor v2.0"
    )

    args = parser.parse_args()

    # Handle example config creation
    if args.create_example:
        create_example_config()
        return 0

    # Load and validate configuration
    try:
        config = ConfigLoader.load(args.config)
        print(f"✅ Configuration loaded: {len(config.targets)} targets found")
    except Exception as e:
        print(f"❌ Configuration error: {e}")
        print(f"💡 Use --create-example to generate an example configuration")
        return 1

    # Initialize logging manager
    try:
        logger_manager = LoggerManager(
            log_path=config.log_file,
            log_level=config.log_level,
            mongodb_config=config.mongodb
        )
        print(f"✅ Logger initialized (MongoDB: {'enabled' if logger_manager.mongodb_enabled else 'disabled'})")
    except Exception as e:
        print(f"❌ Logger initialization failed: {e}")
        return 1

    # Validate targets
    active_targets = [t for t in config.targets if t.active]
    if not active_targets:
        logger_manager.log_configuration_error("No active targets found in configuration")
        return 1

    print(f"📊 Active targets: {len(active_targets)}/{len(config.targets)}")
    for target in active_targets:
        print(f"  - {target.name} ({target.method}): {target.service} [interval: {target.interval_sec}s]")

    # Initialize service monitor
    service_monitor = ServiceMonitor(logger_manager)

    # Run monitoring
    try:
        if args.once:
            print("🔍 Running single monitoring cycle...")
            service_monitor.run_once(active_targets)
            print("✅ Single monitoring cycle completed")
        else:
            print("🔄 Starting continuous monitoring (Ctrl+C to stop)...")
            service_monitor.run_continuous(active_targets, sleep_interval=1)

    except KeyboardInterrupt:
        print("\n🛑 Monitoring stopped by user")
        return 0
    except Exception as e:
        print(f"❌ Monitoring failed: {e}")
        logger_manager.error(f"Critical error in monitoring loop: {e}")
        return 1

    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)