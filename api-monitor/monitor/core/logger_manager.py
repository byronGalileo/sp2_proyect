import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from typing import Optional, Dict, Any
from datetime import datetime

# Add parent directory to path for database imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from database import log_operations, LogEntry, EventEntry, LogLevel, ServiceStatus as MongoServiceStatus

class LoggerManager:
    """Unified logging manager with MongoDB integration"""

    def __init__(self, log_path: str, log_level: str = "INFO", mongodb_config: Optional[Dict[str, Any]] = None):
        self.log_path = log_path
        self.log_level = log_level.upper()
        self.mongodb_enabled = mongodb_config and mongodb_config.get("enabled", False)
        self.mongodb_config = mongodb_config or {}

        # Set up traditional file logger
        self.logger = self._setup_file_logger()

        # Initialize MongoDB connection if enabled
        if self.mongodb_enabled:
            self._setup_mongodb()

    def _setup_file_logger(self) -> logging.Logger:
        """Set up traditional file logging"""
        logger = logging.getLogger("service_monitor")

        # Avoid duplicate handlers
        if logger.handlers:
            return logger

        logger.setLevel(getattr(logging, self.log_level, logging.INFO))

        # Create log directory
        os.makedirs(os.path.dirname(self.log_path), exist_ok=True)

        # File handler with rotation
        file_handler = RotatingFileHandler(
            self.log_path,
            maxBytes=2*1024*1024,  # 2MB
            backupCount=5
        )

        # Console handler
        console_handler = logging.StreamHandler()

        # Formatter
        formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)

        logger.addHandler(file_handler)
        logger.addHandler(console_handler)

        return logger

    def _setup_mongodb(self):
        """Initialize MongoDB connection"""
        try:
            # Set MongoDB environment variables if provided in config
            if "host" in self.mongodb_config:
                os.environ["MONGO_HOST"] = self.mongodb_config["host"]
            if "port" in self.mongodb_config:
                os.environ["MONGO_PORT"] = str(self.mongodb_config["port"])
            if "database" in self.mongodb_config:
                os.environ["MONGO_DB_NAME"] = self.mongodb_config["database"]
            if "username" in self.mongodb_config:
                os.environ["MONGO_USERNAME"] = self.mongodb_config["username"]
            if "password" in self.mongodb_config:
                os.environ["MONGO_PASSWORD"] = self.mongodb_config["password"]

            # Test MongoDB connection
            if log_operations.connection.connect():
                self.logger.info("MongoDB logging enabled and connected")
            else:
                self.logger.warning("MongoDB connection failed, disabling MongoDB logging")
                self.mongodb_enabled = False
        except Exception as e:
            self.logger.error(f"MongoDB setup failed: {e}")
            self.mongodb_enabled = False

    def _log_level_to_mongo(self, level: str) -> LogLevel:
        """Convert logging level to MongoDB LogLevel enum"""
        level_map = {
            "DEBUG": LogLevel.DEBUG,
            "INFO": LogLevel.INFO,
            "WARNING": LogLevel.WARNING,
            "ERROR": LogLevel.ERROR,
            "CRITICAL": LogLevel.CRITICAL
        }
        return level_map.get(level.upper(), LogLevel.INFO)

    def _status_to_mongo(self, is_active: bool) -> MongoServiceStatus:
        """Convert boolean status to MongoDB ServiceStatus enum"""
        return MongoServiceStatus.ACTIVE if is_active else MongoServiceStatus.INACTIVE

    def log_service_status(
        self,
        target_name: str,
        service_name: str,
        status: str,
        is_active: bool,
        host: str = "localhost",
        service_type: str = "local",
        metadata: Optional[Dict[str, Any]] = None,
        error: Optional[str] = None
    ):
        """Log service status check"""
        # Traditional logging
        message = f"[{target_name}] status={status} active={is_active}"
        if error:
            self.logger.error(f"[{target_name}] {error}")
        else:
            self.logger.info(message)

        # MongoDB logging
        if self.mongodb_enabled:
            try:
                log_entry = LogEntry(
                    service_name=service_name,
                    log_level=LogLevel.ERROR if error else LogLevel.INFO,
                    message=error or message,
                    service_type=service_type,
                    host=host,
                    status=self._status_to_mongo(is_active),
                    metadata=metadata or {'original_status': status},
                    tags=[target_name, 'status_check']
                )
                log_operations.save_log(log_entry)
            except Exception as e:
                self.logger.error(f"Failed to save status log to MongoDB: {e}")

    def log_remediation_attempt(
        self,
        target_name: str,
        service_name: str,
        action: str,
        success: bool,
        host: str = "localhost",
        service_type: str = "local",
        metadata: Optional[Dict[str, Any]] = None,
        error_details: Optional[str] = None
    ):
        """Log remediation attempt"""
        # Traditional logging
        if success:
            self.logger.info(f"[{target_name}] {action} executed successfully")
        else:
            self.logger.error(f"[{target_name}] {action} failed: {error_details}")

        # MongoDB logging
        if self.mongodb_enabled:
            try:
                log_level = LogLevel.INFO if success else LogLevel.ERROR
                message = f"{action} {'succeeded' if success else 'failed'}"
                if error_details and not success:
                    message += f": {error_details}"

                log_entry = LogEntry(
                    service_name=service_name,
                    log_level=log_level,
                    message=message,
                    service_type=service_type,
                    host=host,
                    metadata=metadata or {},
                    tags=[target_name, 'remediation', action]
                )
                log_operations.save_log(log_entry)

                # Also create an event for remediation attempts
                event_entry = EventEntry(
                    service_name=service_name,
                    event_type='service_remediation',
                    description=f"Attempted {action} on {service_name}: {'Success' if success else 'Failed'}",
                    host=host,
                    severity=log_level,
                    metadata={
                        'action': action,
                        'success': success,
                        'target_name': target_name,
                        'error_details': error_details,
                        **(metadata or {})
                    }
                )
                log_operations.save_event(event_entry)

            except Exception as e:
                self.logger.error(f"Failed to save remediation log to MongoDB: {e}")

    def log_monitor_start(self, target_count: int, config_info: Optional[Dict[str, Any]] = None):
        """Log monitor startup"""
        message = f"Starting monitor with {target_count} targets"
        self.logger.info(message)

        if self.mongodb_enabled:
            try:
                event_entry = EventEntry(
                    service_name="service_monitor",
                    event_type="monitor_start",
                    description=message,
                    severity=LogLevel.INFO,
                    metadata={
                        'target_count': target_count,
                        'mongodb_enabled': self.mongodb_enabled,
                        **(config_info or {})
                    }
                )
                log_operations.save_event(event_entry)
            except Exception as e:
                self.logger.error(f"Failed to save monitor start event to MongoDB: {e}")

    def log_monitor_stop(self, reason: str = "shutdown"):
        """Log monitor shutdown"""
        message = f"Monitor stopping: {reason}"
        self.logger.info(message)

        if self.mongodb_enabled:
            try:
                event_entry = EventEntry(
                    service_name="service_monitor",
                    event_type="monitor_stop",
                    description=message,
                    severity=LogLevel.INFO,
                    metadata={'reason': reason}
                )
                log_operations.save_event(event_entry)
            except Exception as e:
                self.logger.error(f"Failed to save monitor stop event to MongoDB: {e}")

    def log_configuration_error(self, error: str, metadata: Optional[Dict[str, Any]] = None):
        """Log configuration errors"""
        self.logger.error(f"Configuration error: {error}")

        if self.mongodb_enabled:
            try:
                log_entry = LogEntry(
                    service_name="service_monitor",
                    log_level=LogLevel.ERROR,
                    message=f"Configuration error: {error}",
                    service_type="local",
                    host="localhost",
                    metadata=metadata or {},
                    tags=['configuration', 'error']
                )
                log_operations.save_log(log_entry)
            except Exception as e:
                self.logger.error(f"Failed to save configuration error to MongoDB: {e}")

    def info(self, message: str):
        """Standard info logging"""
        self.logger.info(message)

    def warning(self, message: str):
        """Standard warning logging"""
        self.logger.warning(message)

    def error(self, message: str):
        """Standard error logging"""
        self.logger.error(message)

    def debug(self, message: str):
        """Standard debug logging"""
        self.logger.debug(message)