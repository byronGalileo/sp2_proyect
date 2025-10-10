from datetime import datetime
from typing import Dict, Any, Optional, List
from enum import Enum

class LogLevel(Enum):
    """Log level enumeration"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"

class ServiceStatus(Enum):
    """Service status enumeration"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    FAILED = "failed"
    UNKNOWN = "unknown"

class LogEntry:
    """Log entry model for MongoDB storage"""

    def __init__(
        self,
        service_name: str,
        log_level: LogLevel,
        message: str,
        timestamp: Optional[datetime] = None,
        service_type: Optional[str] = None,
        host: Optional[str] = None,
        status: Optional[ServiceStatus] = None,
        metadata: Optional[Dict[str, Any]] = None,
        tags: Optional[List[str]] = None,
        sent_to_user: bool = False
    ):
        self.service_name = service_name
        self.log_level = log_level
        self.message = message
        self.timestamp = timestamp or datetime.utcnow()
        self.service_type = service_type or "unknown"
        self.host = host or "localhost"
        self.status = status
        self.metadata = metadata or {}
        self.tags = tags or []
        self.sent_to_user = sent_to_user

    def to_document(self) -> Dict[str, Any]:
        """Convert log entry to MongoDB document"""
        doc = {
            'service_name': self.service_name,
            'service_type': self.service_type,
            'host': self.host,
            'log_level': self.log_level.value,
            'message': self.message,
            'timestamp': self.timestamp,
            'metadata': self.metadata,
            'tags': self.tags,
            'sent_to_user': self.sent_to_user
        }

        if self.status:
            doc['status'] = self.status.value

        # Add indexed fields for efficient querying
        doc['date'] = self.timestamp.strftime('%Y-%m-%d')
        doc['hour'] = self.timestamp.hour
        doc['service_key'] = f"{self.host}:{self.service_name}"

        return doc

    @classmethod
    def from_monitor_log(cls, log_line: str, host: str = "localhost") -> Optional['LogEntry']:
        """Create LogEntry from monitor log line

        Example log format:
        2025-09-11 22:33:41,792 INFO [local-my-sql] status=active active=True
        """
        import re
        from datetime import datetime

        # Parse log line pattern
        pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) (\w+) \[([^\]]+)\] (.+)'
        match = re.match(pattern, log_line.strip())

        if not match:
            return None

        timestamp_str, level, service_name, message = match.groups()

        # Parse timestamp
        try:
            timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S,%f')
        except ValueError:
            timestamp = datetime.utcnow()

        # Extract service type from service name
        service_type = "local" if service_name.startswith("local-") else "remote"
        clean_service_name = service_name.replace("local-", "").replace("remote-", "")

        # Parse status from message if present
        status = None
        metadata = {}

        if "status=" in message:
            # Extract status and active state
            status_match = re.search(r'status=(\w+)', message)
            active_match = re.search(r'active=(\w+)', message)

            if status_match:
                status_value = status_match.group(1)
                status = ServiceStatus.ACTIVE if status_value == "active" else ServiceStatus.INACTIVE

            if active_match:
                metadata['active'] = active_match.group(1) == "True"

        return cls(
            service_name=clean_service_name,
            log_level=LogLevel(level),
            message=message,
            timestamp=timestamp,
            service_type=service_type,
            host=host,
            status=status,
            metadata=metadata
        )

class EventEntry:
    """Event entry for significant service events"""

    def __init__(
        self,
        service_name: str,
        event_type: str,
        description: str,
        timestamp: Optional[datetime] = None,
        host: Optional[str] = None,
        severity: Optional[LogLevel] = None,
        duration: Optional[float] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        self.service_name = service_name
        self.event_type = event_type
        self.description = description
        self.timestamp = timestamp or datetime.utcnow()
        self.host = host or "localhost"
        self.severity = severity or LogLevel.INFO
        self.duration = duration
        self.metadata = metadata or {}

    def to_document(self) -> Dict[str, Any]:
        """Convert event entry to MongoDB document"""
        doc = {
            'service_name': self.service_name,
            'event_type': self.event_type,
            'description': self.description,
            'timestamp': self.timestamp,
            'host': self.host,
            'severity': self.severity.value,
            'metadata': self.metadata,
            'date': self.timestamp.strftime('%Y-%m-%d'),
            'service_key': f"{self.host}:{self.service_name}"
        }

        if self.duration:
            doc['duration'] = self.duration

        return doc