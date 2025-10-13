"""
MongoDB models for the service monitoring system
Includes Host, Service, and MonitoringHistory models
"""

from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from enum import Enum


class HostStatus(Enum):
    """Host operational status"""
    ACTIVE = "active"
    MAINTENANCE = "maintenance"
    DECOMMISSIONED = "decommissioned"


class ServiceStatus(Enum):
    """Service status enumeration"""
    RUNNING = "running"
    STOPPED = "stopped"
    UNKNOWN = "unknown"
    ERROR = "error"
    WARNING = "warning"


class MonitoringMethod(Enum):
    """Monitoring method types"""
    SSH = "ssh"
    HTTP = "http"
    TCP = "tcp"
    DATABASE = "database"
    CUSTOM = "custom"


class RecoveryAction(Enum):
    """Recovery action types"""
    RESTART = "restart"
    RELOAD = "reload"
    STOP = "stop"
    START = "start"
    CUSTOM_SCRIPT = "custom_script"


class CheckType(Enum):
    """Check type for monitoring history"""
    STATUS_CHECK = "status_check"
    HEALTH_CHECK = "health_check"
    PERFORMANCE = "performance"


class Host:
    """Host/Server model for MongoDB storage"""

    def __init__(
        self,
        host_id: str,
        hostname: str,
        ip_address: str,
        environment: str,
        region: str,
        ssh_user: str,
        ssh_port: int = 22,
        ssh_key_path: Optional[str] = None,
        use_sudo: bool = False,
        location: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        status: HostStatus = HostStatus.ACTIVE,
        created_at: Optional[datetime] = None,
        updated_at: Optional[datetime] = None,
        last_seen: Optional[datetime] = None
    ):
        self.host_id = host_id
        self.hostname = hostname
        self.ip_address = ip_address
        self.environment = environment
        self.region = region
        self.ssh_user = ssh_user
        self.ssh_port = ssh_port
        self.ssh_key_path = ssh_key_path
        self.use_sudo = use_sudo
        self.location = location or {}
        self.metadata = metadata or {"tags": []}
        self.status = status
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
        self.last_seen = last_seen or datetime.utcnow()

    def to_document(self) -> Dict[str, Any]:
        """Convert host to MongoDB document"""
        return {
            "host_id": self.host_id,
            "hostname": self.hostname,
            "ip_address": self.ip_address,
            "environment": self.environment,
            "region": self.region,
            "location": self.location,
            "ssh_config": {
                "user": self.ssh_user,
                "port": self.ssh_port,
                "key_path": self.ssh_key_path,
                "use_sudo": self.use_sudo
            },
            "metadata": self.metadata,
            "status": self.status.value if isinstance(self.status, HostStatus) else self.status,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "last_seen": self.last_seen
        }

    @classmethod
    def from_document(cls, doc: Dict[str, Any]) -> 'Host':
        """Create Host from MongoDB document"""
        ssh_config = doc.get("ssh_config", {})
        return cls(
            host_id=doc["host_id"],
            hostname=doc["hostname"],
            ip_address=doc["ip_address"],
            environment=doc["environment"],
            region=doc["region"],
            ssh_user=ssh_config.get("user", "root"),
            ssh_port=ssh_config.get("port", 22),
            ssh_key_path=ssh_config.get("key_path"),
            use_sudo=ssh_config.get("use_sudo", False),
            location=doc.get("location", {}),
            metadata=doc.get("metadata", {}),
            status=HostStatus(doc.get("status", "active")),
            created_at=doc.get("created_at"),
            updated_at=doc.get("updated_at"),
            last_seen=doc.get("last_seen")
        )


class Service:
    """Service model for MongoDB storage"""

    def __init__(
        self,
        service_id: str,
        host_id: str,
        service_name: str,
        service_type: str,
        display_name: Optional[str] = None,
        description: Optional[str] = None,
        environment: str = "production",
        region: str = "default",
        monitoring_enabled: bool = True,
        monitoring_method: MonitoringMethod = MonitoringMethod.SSH,
        interval_sec: int = 60,
        timeout_sec: int = 30,
        retry_attempts: int = 3,
        retry_delay_sec: int = 5,
        recover_on_down: bool = False,
        recover_action: RecoveryAction = RecoveryAction.RESTART,
        custom_script: Optional[str] = None,
        max_recovery_attempts: int = 3,
        recovery_cooldown_sec: int = 300,
        notify_before_recovery: bool = True,
        alerting_enabled: bool = True,
        alerting_channels: Optional[List[str]] = None,
        severity: str = "medium",
        current_status: ServiceStatus = ServiceStatus.UNKNOWN,
        tags: Optional[List[str]] = None,
        dependencies: Optional[List[str]] = None,
        created_at: Optional[datetime] = None,
        updated_at: Optional[datetime] = None,
        last_check: Optional[datetime] = None,
        last_status_change: Optional[datetime] = None,
        uptime_percentage: float = 0.0,
        consecutive_failures: int = 0
    ):
        self.service_id = service_id
        self.host_id = host_id
        self.service_name = service_name
        self.service_type = service_type
        self.display_name = display_name or service_name
        self.description = description or f"Monitoring for {service_name}"
        self.environment = environment
        self.region = region
        self.monitoring_enabled = monitoring_enabled
        self.monitoring_method = monitoring_method
        self.interval_sec = interval_sec
        self.timeout_sec = timeout_sec
        self.retry_attempts = retry_attempts
        self.retry_delay_sec = retry_delay_sec
        self.recover_on_down = recover_on_down
        self.recover_action = recover_action
        self.custom_script = custom_script
        self.max_recovery_attempts = max_recovery_attempts
        self.recovery_cooldown_sec = recovery_cooldown_sec
        self.notify_before_recovery = notify_before_recovery
        self.alerting_enabled = alerting_enabled
        self.alerting_channels = alerting_channels or ["email"]
        self.severity = severity
        self.current_status = current_status
        self.tags = tags or []
        self.dependencies = dependencies or []
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
        self.last_check = last_check or datetime.utcnow()
        self.last_status_change = last_status_change or datetime.utcnow()
        self.uptime_percentage = uptime_percentage
        self.consecutive_failures = consecutive_failures

    def to_document(self) -> Dict[str, Any]:
        """Convert service to MongoDB document"""
        return {
            "service_id": self.service_id,
            "host_id": self.host_id,
            "service_name": self.service_name,
            "service_type": self.service_type,
            "display_name": self.display_name,
            "description": self.description,
            "monitoring": {
                "method": self.monitoring_method.value if isinstance(self.monitoring_method, MonitoringMethod) else self.monitoring_method,
                "enabled": self.monitoring_enabled,
                "interval_sec": self.interval_sec,
                "timeout_sec": self.timeout_sec,
                "retry_attempts": self.retry_attempts,
                "retry_delay_sec": self.retry_delay_sec
            },
            "recovery": {
                "recover_on_down": self.recover_on_down,
                "recover_action": self.recover_action.value if isinstance(self.recover_action, RecoveryAction) else self.recover_action,
                "custom_script": self.custom_script,
                "max_recovery_attempts": self.max_recovery_attempts,
                "recovery_cooldown_sec": self.recovery_cooldown_sec,
                "notify_before_recovery": self.notify_before_recovery
            },
            "alerting": {
                "enabled": self.alerting_enabled,
                "channels": self.alerting_channels,
                "severity": self.severity,
                "escalation_policy": None,
                "mute_until": None
            },
            "health_check": {
                "enabled": False,
                "endpoint": None,
                "expected_response": None,
                "custom_check": None
            },
            "current_status": self.current_status.value if isinstance(self.current_status, ServiceStatus) else self.current_status,
            "last_check": self.last_check,
            "last_status_change": self.last_status_change,
            "uptime_percentage": self.uptime_percentage,
            "consecutive_failures": self.consecutive_failures,
            "environment": self.environment,
            "region": self.region,
            "tags": self.tags,
            "dependencies": self.dependencies,
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }

    @classmethod
    def from_document(cls, doc: Dict[str, Any]) -> 'Service':
        """Create Service from MongoDB document"""
        monitoring = doc.get("monitoring", {})
        recovery = doc.get("recovery", {})
        alerting = doc.get("alerting", {})

        return cls(
            service_id=doc["service_id"],
            host_id=doc["host_id"],
            service_name=doc["service_name"],
            service_type=doc["service_type"],
            display_name=doc.get("display_name"),
            description=doc.get("description"),
            environment=doc.get("environment", "production"),
            region=doc.get("region", "default"),
            monitoring_enabled=monitoring.get("enabled", True),
            monitoring_method=MonitoringMethod(monitoring.get("method", "ssh")),
            interval_sec=monitoring.get("interval_sec", 60),
            timeout_sec=monitoring.get("timeout_sec", 30),
            retry_attempts=monitoring.get("retry_attempts", 3),
            retry_delay_sec=monitoring.get("retry_delay_sec", 5),
            recover_on_down=recovery.get("recover_on_down", False),
            recover_action=RecoveryAction(recovery.get("recover_action", "restart")),
            custom_script=recovery.get("custom_script"),
            max_recovery_attempts=recovery.get("max_recovery_attempts", 3),
            recovery_cooldown_sec=recovery.get("recovery_cooldown_sec", 300),
            notify_before_recovery=recovery.get("notify_before_recovery", True),
            alerting_enabled=alerting.get("enabled", True),
            alerting_channels=alerting.get("channels", ["email"]),
            severity=alerting.get("severity", "medium"),
            current_status=ServiceStatus(doc.get("current_status", "unknown")),
            tags=doc.get("tags", []),
            dependencies=doc.get("dependencies", []),
            created_at=doc.get("created_at"),
            updated_at=doc.get("updated_at"),
            last_check=doc.get("last_check"),
            last_status_change=doc.get("last_status_change"),
            uptime_percentage=doc.get("uptime_percentage", 0.0),
            consecutive_failures=doc.get("consecutive_failures", 0)
        )


class MonitoringHistory:
    """Monitoring history entry for MongoDB storage"""

    def __init__(
        self,
        service_id: str,
        host_id: str,
        check_type: CheckType = CheckType.STATUS_CHECK,
        status: str = "unknown",
        status_code: int = 0,
        response_time_ms: Optional[int] = None,
        metrics: Optional[Dict[str, Any]] = None,
        error: Optional[str] = None,
        error_details: Optional[str] = None,
        recovery_attempted: bool = False,
        recovery_action: Optional[str] = None,
        recovery_success: Optional[bool] = None,
        recovery_message: Optional[str] = None,
        timestamp: Optional[datetime] = None,
        retention_days: int = 30
    ):
        self.service_id = service_id
        self.host_id = host_id
        self.check_type = check_type
        self.status = status
        self.status_code = status_code
        self.response_time_ms = response_time_ms
        self.metrics = metrics or {}
        self.error = error
        self.error_details = error_details
        self.recovery_attempted = recovery_attempted
        self.recovery_action = recovery_action
        self.recovery_success = recovery_success
        self.recovery_message = recovery_message
        self.timestamp = timestamp or datetime.utcnow()
        self.expires_at = self.timestamp + timedelta(days=retention_days)

    def to_document(self) -> Dict[str, Any]:
        """Convert monitoring history to MongoDB document"""
        return {
            "service_id": self.service_id,
            "host_id": self.host_id,
            "timestamp": self.timestamp,
            "check_type": self.check_type.value if isinstance(self.check_type, CheckType) else self.check_type,
            "status": self.status,
            "status_code": self.status_code,
            "response_time_ms": self.response_time_ms,
            "metrics": self.metrics,
            "error": self.error,
            "error_details": self.error_details,
            "recovery_attempted": self.recovery_attempted,
            "recovery_action": self.recovery_action,
            "recovery_success": self.recovery_success,
            "recovery_message": self.recovery_message,
            "expires_at": self.expires_at
        }

    @classmethod
    def from_document(cls, doc: Dict[str, Any]) -> 'MonitoringHistory':
        """Create MonitoringHistory from MongoDB document"""
        return cls(
            service_id=doc["service_id"],
            host_id=doc["host_id"],
            check_type=CheckType(doc.get("check_type", "status_check")),
            status=doc.get("status", "unknown"),
            status_code=doc.get("status_code", 0),
            response_time_ms=doc.get("response_time_ms"),
            metrics=doc.get("metrics", {}),
            error=doc.get("error"),
            error_details=doc.get("error_details"),
            recovery_attempted=doc.get("recovery_attempted", False),
            recovery_action=doc.get("recovery_action"),
            recovery_success=doc.get("recovery_success"),
            recovery_message=doc.get("recovery_message"),
            timestamp=doc.get("timestamp")
        )
