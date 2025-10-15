"""
FastAPI routers for Hosts and Services management
"""

import json
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, HTTPException, Query, Path, Body
from pydantic import BaseModel, Field, validator

from database.host_operations import host_operations
from database.service_operations import service_operations
from database.monitoring_operations import monitoring_operations
from database.monitoring_models import (
    Host, Service, MonitoringHistory,
    HostStatus, ServiceStatus, MonitoringMethod, RecoveryAction
)

logger = logging.getLogger(__name__)

# Create routers
hosts_router = APIRouter(prefix="/hosts", tags=["Hosts"])
services_router = APIRouter(prefix="/services", tags=["Services"])
config_router = APIRouter(prefix="/config", tags=["Configuration"])
monitoring_router = APIRouter(prefix="/monitoring", tags=["Monitoring"])


# ==================== PYDANTIC MODELS ====================

class SSHConfig(BaseModel):
    user: str = Field(..., description="SSH username")
    port: int = Field(22, description="SSH port", ge=1, le=65535)
    key_path: Optional[str] = Field(None, description="Path to SSH key file")
    use_sudo: bool = Field(False, description="Whether to use sudo for commands")


class LocationInfo(BaseModel):
    datacenter: Optional[str] = Field(None, description="Datacenter name")
    rack: Optional[str] = Field(None, description="Rack identifier")
    zone: Optional[str] = Field(None, description="Zone or availability zone")


class HostMetadata(BaseModel):
    os: Optional[str] = Field(None, description="Operating system")
    purpose: Optional[str] = Field(None, description="Host purpose/description")
    config_path: Optional[str] = Field(None, description="Relative path to monitoring config file")
    config_generated_at: Optional[str] = Field(None, description="Timestamp when config was last generated")
    config_services_count: Optional[int] = Field(None, description="Number of services in the generated config")
    tags: List[str] = Field(default_factory=list, description="Tags for categorization")


class CreateHostRequest(BaseModel):
    host_id: str = Field(..., description="Unique host identifier", min_length=1)
    hostname: str = Field(..., description="Hostname", min_length=1)
    ip_address: str = Field(..., description="IP address")
    environment: str = Field("production", description="Environment (dev/staging/production)")
    region: str = Field("default", description="Region or datacenter")
    ssh_config: SSHConfig
    log_file: Optional[str] = Field(None, description="Log file path for monitoring (default: logs/{host_id}_monitor.log)")
    location: Optional[LocationInfo] = None
    metadata: Optional[HostMetadata] = None
    status: str = Field("active", description="Host status")


class UpdateHostRequest(BaseModel):
    hostname: Optional[str] = Field(None, description="Hostname")
    ip_address: Optional[str] = Field(None, description="IP address")
    environment: Optional[str] = Field(None, description="Environment")
    region: Optional[str] = Field(None, description="Region")
    ssh_config: Optional[SSHConfig] = None
    log_file: Optional[str] = Field(None, description="Log file path for monitoring")
    location: Optional[LocationInfo] = None
    metadata: Optional[HostMetadata] = None
    status: Optional[str] = Field(None, description="Host status")


class MonitoringConfig(BaseModel):
    method: str = Field("ssh", description="Monitoring method")
    enabled: bool = Field(True, description="Enable monitoring")
    interval_sec: int = Field(60, description="Check interval in seconds", ge=10)
    timeout_sec: int = Field(30, description="Timeout in seconds", ge=5)
    retry_attempts: int = Field(3, description="Number of retry attempts", ge=0)
    retry_delay_sec: int = Field(5, description="Delay between retries in seconds", ge=1)


class RecoveryConfig(BaseModel):
    recover_on_down: bool = Field(False, description="Attempt recovery when service is down")
    recover_action: str = Field("restart", description="Recovery action (restart/reload/stop/start)")
    custom_script: Optional[str] = Field(None, description="Custom recovery script path")
    max_recovery_attempts: int = Field(3, description="Maximum recovery attempts", ge=0)
    recovery_cooldown_sec: int = Field(300, description="Cooldown period between recoveries", ge=0)
    notify_before_recovery: bool = Field(True, description="Send notification before recovery")


class AlertingConfig(BaseModel):
    enabled: bool = Field(True, description="Enable alerting")
    channels: List[str] = Field(default_factory=lambda: ["email"], description="Alert channels")
    severity: str = Field("medium", description="Alert severity (low/medium/high/critical)")


class CreateServiceRequest(BaseModel):
    service_id: str = Field(..., description="Unique service identifier", min_length=1)
    host_id: str = Field(..., description="Host identifier", min_length=1)
    service_name: str = Field(..., description="Service name (e.g., mysql.service)", min_length=1)
    service_type: str = Field(..., description="Service type (e.g., mysql, nginx)", min_length=1)
    display_name: Optional[str] = Field(None, description="Display name")
    description: Optional[str] = Field(None, description="Service description")
    environment: str = Field("production", description="Environment")
    region: str = Field("default", description="Region")
    monitoring: Optional[MonitoringConfig] = None
    recovery: Optional[RecoveryConfig] = None
    alerting: Optional[AlertingConfig] = None
    tags: List[str] = Field(default_factory=list, description="Service tags")
    dependencies: List[str] = Field(default_factory=list, description="Service dependencies")

    @validator('service_name')
    def validate_service_name(cls, v):
        """Ensure service name ends with .service"""
        if not v.endswith('.service'):
            return f"{v}.service"
        return v


class UpdateServiceRequest(BaseModel):
    service_name: Optional[str] = Field(None, description="Service name")
    service_type: Optional[str] = Field(None, description="Service type")
    display_name: Optional[str] = Field(None, description="Display name")
    description: Optional[str] = Field(None, description="Service description")
    environment: Optional[str] = Field(None, description="Environment")
    region: Optional[str] = Field(None, description="Region")
    monitoring: Optional[MonitoringConfig] = None
    recovery: Optional[RecoveryConfig] = None
    alerting: Optional[AlertingConfig] = None
    tags: Optional[List[str]] = Field(None, description="Service tags")
    dependencies: Optional[List[str]] = Field(None, description="Service dependencies")


class ApiResponse(BaseModel):
    success: bool
    message: str
    data: Optional[Any] = None


# ==================== HOST ENDPOINTS ====================

@hosts_router.post("", response_model=ApiResponse, status_code=201)
async def create_host(request: CreateHostRequest):
    """Create a new host"""
    try:
        # Check if host already exists
        if host_operations.host_exists(request.host_id):
            raise HTTPException(status_code=409, detail=f"Host with ID '{request.host_id}' already exists")

        # Create Host object
        host = Host(
            host_id=request.host_id,
            hostname=request.hostname,
            ip_address=request.ip_address,
            environment=request.environment,
            region=request.region,
            ssh_user=request.ssh_config.user,
            ssh_port=request.ssh_config.port,
            ssh_key_path=request.ssh_config.key_path,
            use_sudo=request.ssh_config.use_sudo,
            log_file=request.log_file,
            location=request.location.dict() if request.location else {},
            metadata=request.metadata.dict() if request.metadata else {"tags": []},
            status=HostStatus(request.status)
        )

        # Save to database
        host_id = host_operations.create_host(host)

        if host_id:
            return ApiResponse(
                success=True,
                message=f"Host '{host_id}' created successfully",
                data={"host_id": host_id}
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to create host")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating host: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create host: {str(e)}")


@hosts_router.get("", response_model=ApiResponse)
async def get_hosts(
    environment: Optional[str] = Query(None, description="Filter by environment"),
    region: Optional[str] = Query(None, description="Filter by region"),
    status: Optional[str] = Query(None, description="Filter by status"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of results"),
    skip: int = Query(0, ge=0, description="Number of results to skip")
):
    """Get all hosts with optional filters"""
    try:
        hosts = host_operations.get_all_hosts(
            environment=environment,
            region=region,
            status=status,
            limit=limit,
            skip=skip
        )

        return ApiResponse(
            success=True,
            message=f"Retrieved {len(hosts)} hosts",
            data={"hosts": hosts, "count": len(hosts)}
        )

    except Exception as e:
        logger.error(f"Error getting hosts: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get hosts: {str(e)}")


@hosts_router.get("/{host_id}", response_model=ApiResponse)
async def get_host(host_id: str = Path(..., description="Host identifier")):
    """Get a specific host by ID"""
    try:
        host = host_operations.get_host(host_id)

        if not host:
            raise HTTPException(status_code=404, detail=f"Host '{host_id}' not found")

        return ApiResponse(
            success=True,
            message="Host retrieved successfully",
            data=host
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting host: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get host: {str(e)}")


@hosts_router.put("/{host_id}", response_model=ApiResponse)
async def update_host(
    host_id: str = Path(..., description="Host identifier"),
    request: UpdateHostRequest = Body(...)
):
    """Update a host"""
    try:
        # Check if host exists
        if not host_operations.host_exists(host_id):
            raise HTTPException(status_code=404, detail=f"Host '{host_id}' not found")

        # Build update data
        update_data = {}
        if request.hostname:
            update_data["hostname"] = request.hostname
        if request.ip_address:
            update_data["ip_address"] = request.ip_address
        if request.environment:
            update_data["environment"] = request.environment
        if request.region:
            update_data["region"] = request.region
        if request.ssh_config:
            update_data["ssh_config"] = request.ssh_config.dict()
        if request.log_file:
            update_data["log_file"] = request.log_file
        if request.location:
            update_data["location"] = request.location.dict()
        if request.metadata:
            update_data["metadata"] = request.metadata.dict()
        if request.status:
            update_data["status"] = request.status

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        # Update host
        success = host_operations.update_host(host_id, update_data)

        if success:
            return ApiResponse(
                success=True,
                message=f"Host '{host_id}' updated successfully",
                data={"host_id": host_id}
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to update host")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating host: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update host: {str(e)}")


@hosts_router.delete("/{host_id}", response_model=ApiResponse)
async def delete_host(
    host_id: str = Path(..., description="Host identifier"),
    delete_services: bool = Query(True, description="Also delete associated services")
):
    """Delete a host"""
    try:
        # Check if host exists
        if not host_operations.host_exists(host_id):
            raise HTTPException(status_code=404, detail=f"Host '{host_id}' not found")

        # Delete host
        success = host_operations.delete_host(host_id, delete_services=delete_services)

        if success:
            return ApiResponse(
                success=True,
                message=f"Host '{host_id}' deleted successfully",
                data={"host_id": host_id, "services_deleted": delete_services}
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to delete host")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting host: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete host: {str(e)}")


@hosts_router.get("/metadata/environments", response_model=ApiResponse)
async def get_environments():
    """Get list of all unique environments"""
    try:
        environments = host_operations.get_environments()
        return ApiResponse(
            success=True,
            message=f"Retrieved {len(environments)} environments",
            data={"environments": environments}
        )
    except Exception as e:
        logger.error(f"Error getting environments: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get environments: {str(e)}")


@hosts_router.get("/metadata/regions", response_model=ApiResponse)
async def get_regions():
    """Get list of all unique regions"""
    try:
        regions = host_operations.get_regions()
        return ApiResponse(
            success=True,
            message=f"Retrieved {len(regions)} regions",
            data={"regions": regions}
        )
    except Exception as e:
        logger.error(f"Error getting regions: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get regions: {str(e)}")


# ==================== SERVICE ENDPOINTS ====================

@services_router.post("", response_model=ApiResponse, status_code=201)
async def create_service(request: CreateServiceRequest):
    """Create a new service"""
    try:
        # Check if service already exists
        if service_operations.service_exists(request.service_id):
            raise HTTPException(status_code=409, detail=f"Service with ID '{request.service_id}' already exists")

        # Check if host exists
        if not host_operations.host_exists(request.host_id):
            raise HTTPException(status_code=404, detail=f"Host '{request.host_id}' not found")

        # Get host to inherit environment and region if not specified
        host = host_operations.get_host(request.host_id)

        # Create Service object
        monitoring = request.monitoring or MonitoringConfig()
        recovery = request.recovery or RecoveryConfig()
        alerting = request.alerting or AlertingConfig()

        service = Service(
            service_id=request.service_id,
            host_id=request.host_id,
            service_name=request.service_name,
            service_type=request.service_type,
            display_name=request.display_name,
            description=request.description,
            environment=request.environment or host.get("environment", "production"),
            region=request.region or host.get("region", "default"),
            monitoring_enabled=monitoring.enabled,
            monitoring_method=MonitoringMethod(monitoring.method),
            interval_sec=monitoring.interval_sec,
            timeout_sec=monitoring.timeout_sec,
            retry_attempts=monitoring.retry_attempts,
            retry_delay_sec=monitoring.retry_delay_sec,
            recover_on_down=recovery.recover_on_down,
            recover_action=RecoveryAction(recovery.recover_action),
            custom_script=recovery.custom_script,
            max_recovery_attempts=recovery.max_recovery_attempts,
            recovery_cooldown_sec=recovery.recovery_cooldown_sec,
            notify_before_recovery=recovery.notify_before_recovery,
            alerting_enabled=alerting.enabled,
            alerting_channels=alerting.channels,
            severity=alerting.severity,
            tags=request.tags,
            dependencies=request.dependencies
        )

        # Save to database
        service_id = service_operations.create_service(service)

        if service_id:
            return ApiResponse(
                success=True,
                message=f"Service '{service_id}' created successfully",
                data={"service_id": service_id}
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to create service")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating service: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create service: {str(e)}")


@services_router.get("", response_model=ApiResponse)
async def get_services(
    host_id: Optional[str] = Query(None, description="Filter by host"),
    service_type: Optional[str] = Query(None, description="Filter by service type"),
    environment: Optional[str] = Query(None, description="Filter by environment"),
    region: Optional[str] = Query(None, description="Filter by region"),
    status: Optional[str] = Query(None, description="Filter by status"),
    enabled_only: bool = Query(False, description="Only return enabled services"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of results"),
    skip: int = Query(0, ge=0, description="Number of results to skip")
):
    """Get all services with optional filters"""
    try:
        services = service_operations.get_all_services(
            host_id=host_id,
            service_type=service_type,
            environment=environment,
            region=region,
            status=status,
            enabled_only=enabled_only,
            limit=limit,
            skip=skip
        )

        return ApiResponse(
            success=True,
            message=f"Retrieved {len(services)} services",
            data={"services": services, "count": len(services)}
        )

    except Exception as e:
        logger.error(f"Error getting services: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get services: {str(e)}")


@services_router.get("/{service_id}", response_model=ApiResponse)
async def get_service(service_id: str = Path(..., description="Service identifier")):
    """Get a specific service by ID"""
    try:
        service = service_operations.get_service(service_id)

        if not service:
            raise HTTPException(status_code=404, detail=f"Service '{service_id}' not found")

        return ApiResponse(
            success=True,
            message="Service retrieved successfully",
            data=service
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting service: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get service: {str(e)}")


@services_router.put("/{service_id}", response_model=ApiResponse)
async def update_service(
    service_id: str = Path(..., description="Service identifier"),
    request: UpdateServiceRequest = Body(...)
):
    """Update a service"""
    try:
        # Check if service exists
        if not service_operations.service_exists(service_id):
            raise HTTPException(status_code=404, detail=f"Service '{service_id}' not found")

        # Build update data
        update_data = {}
        if request.service_name:
            # Ensure .service extension
            if not request.service_name.endswith('.service'):
                request.service_name = f"{request.service_name}.service"
            update_data["service_name"] = request.service_name
        if request.service_type:
            update_data["service_type"] = request.service_type
        if request.display_name:
            update_data["display_name"] = request.display_name
        if request.description:
            update_data["description"] = request.description
        if request.environment:
            update_data["environment"] = request.environment
        if request.region:
            update_data["region"] = request.region
        if request.monitoring:
            update_data["monitoring"] = request.monitoring.dict()
        if request.recovery:
            update_data["recovery"] = request.recovery.dict()
        if request.alerting:
            update_data["alerting"] = request.alerting.dict()
        if request.tags is not None:
            update_data["tags"] = request.tags
        if request.dependencies is not None:
            update_data["dependencies"] = request.dependencies

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        # Update service
        success = service_operations.update_service(service_id, update_data)

        if success:
            return ApiResponse(
                success=True,
                message=f"Service '{service_id}' updated successfully",
                data={"service_id": service_id}
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to update service")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating service: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update service: {str(e)}")


@services_router.delete("/{service_id}", response_model=ApiResponse)
async def delete_service(service_id: str = Path(..., description="Service identifier")):
    """Delete a service"""
    try:
        # Check if service exists
        if not service_operations.service_exists(service_id):
            raise HTTPException(status_code=404, detail=f"Service '{service_id}' not found")

        # Delete service
        success = service_operations.delete_service(service_id)

        if success:
            return ApiResponse(
                success=True,
                message=f"Service '{service_id}' deleted successfully",
                data={"service_id": service_id}
            )
        else:
            raise HTTPException(status_code=500, detail="Failed to delete service")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting service: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete service: {str(e)}")


@services_router.get("/dashboard/summary", response_model=ApiResponse)
async def get_dashboard_summary():
    """Get dashboard summary with service statistics"""
    try:
        summary = service_operations.get_dashboard_summary()
        return ApiResponse(
            success=True,
            message="Dashboard summary retrieved successfully",
            data=summary
        )
    except Exception as e:
        logger.error(f"Error getting dashboard summary: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get dashboard summary: {str(e)}")


@services_router.get("/attention/needed", response_model=ApiResponse)
async def get_services_needing_attention():
    """Get services that need attention (down, failures, stale)"""
    try:
        services = service_operations.get_services_needing_attention()
        return ApiResponse(
            success=True,
            message="Services needing attention retrieved successfully",
            data=services
        )
    except Exception as e:
        logger.error(f"Error getting services needing attention: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get services needing attention: {str(e)}")


# ==================== CONFIG GENERATION ENDPOINT ====================

@config_router.get("/generate/{host_id}", response_model=ApiResponse)
async def generate_config(
    host_id: str = Path(..., description="Host identifier to generate config for"),
    save_to_file: bool = Query(True, description="Save config to monitor/config/{host_id}_config.json")
):
    """Generate config.json for a specific host and save to monitor/config directory"""
    try:
        # Check if host exists
        host = host_operations.get_host(host_id)
        if not host:
            raise HTTPException(status_code=404, detail=f"Host '{host_id}' not found")

        # Get all enabled services for this host
        services = service_operations.get_all_services(
            host_id=host_id,
            enabled_only=True,
            limit=1000
        )

        if not services:
            return ApiResponse(
                success=True,
                message=f"No enabled services found for host '{host_id}'",
                data={"targets": []}
            )

        # Build config targets
        targets = []
        for service in services:
            # Remove .service extension for config
            service_name_clean = service["service_name"].replace(".service", "")

            monitoring = service.get("monitoring", {})
            recovery = service.get("recovery", {})

            target = {
                "host": host["hostname"],  # Use hostname instead of ip_address
                "name": service.get("display_name", service_name_clean),
                "method": monitoring.get("method", "ssh"),
                "service": service["service_name"],  # Keep the full service name with .service extension
                "interval_sec": monitoring.get("interval_sec", 60),
                "recover_on_down": recovery.get("recover_on_down", False),
                "recover_action": recovery.get("recover_action", "restart"),
                "timeout_sec": monitoring.get("timeout_sec", 30),
                "active": monitoring.get("enabled", True),
                "use_sudo": host["ssh_config"].get("use_sudo", False)
            }

            # Add SSH config only if method is ssh
            if monitoring.get("method", "ssh") == "ssh":
                target["ssh"] = {
                    "user": host["ssh_config"]["user"],
                    "port": host["ssh_config"]["port"]
                }

            targets.append(target)

        # Build complete config structure
        config = {
            "log_file": host.get("log_file", f"logs/{host_id}_monitor.log"),
            "log_level": "INFO",
            "targets": targets
        }

        # Save to file if requested
        if save_to_file:
            import os
            config_dir = os.path.join(os.path.dirname(__file__), "..", "monitor", "config")
            config_dir = os.path.abspath(config_dir)
            config_path = os.path.join(config_dir, f"config.{host_id}.json")

            os.makedirs(config_dir, exist_ok=True)

            with open(config_path, 'w') as f:
                json.dump(config, f, indent=2)

            # Calculate relative path from project root
            relative_path = f"monitor/config/config.{host_id}.json"

            # Update host metadata with config information
            current_metadata = host.get("metadata", {})
            current_metadata["config_path"] = relative_path
            current_metadata["config_generated_at"] = datetime.now(timezone.utc).isoformat()
            current_metadata["config_services_count"] = len(targets)

            # Update host in database
            update_success = host_operations.update_host(host_id, {"metadata": current_metadata})

            if update_success:
                logger.info(f"Config for host '{host_id}' saved to {config_path} and metadata updated")
            else:
                logger.warning(f"Config saved but failed to update host metadata for '{host_id}'")

            return ApiResponse(
                success=True,
                message=f"Generated config for host '{host_id}' with {len(targets)} services and saved to {relative_path}",
                data={
                    "config": config,
                    "relative_path": relative_path,
                    "host_id": host_id,
                    "services_count": len(targets),
                    "metadata_updated": update_success
                }
            )

        return ApiResponse(
            success=True,
            message=f"Generated config for host '{host_id}' with {len(targets)} services",
            data=config
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating config for host '{host_id}': {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate config: {str(e)}")


@config_router.get("/download/{host_id}")
async def download_config(
    host_id: str = Path(..., description="Host identifier to download config for")
):
    """Download config.json file for a specific host"""
    from fastapi.responses import Response

    try:
        # Generate config without saving to file
        result = await generate_config(host_id, save_to_file=False)
        config_data = result.data

        # Convert to JSON string
        json_str = json.dumps(config_data, indent=2)

        return Response(
            content=json_str,
            media_type="application/json",
            headers={
                "Content-Disposition": f"attachment; filename={host_id}_config.json"
            }
        )

    except Exception as e:
        logger.error(f"Error downloading config for host '{host_id}': {e}")
        raise HTTPException(status_code=500, detail=f"Failed to download config: {str(e)}")


# ==================== MONITOR MANAGEMENT ENDPOINTS ====================

import subprocess
import os
import psutil
import signal
import traceback
import time
from threading import Lock

# Global variables for process management
monitor_processes = {}  # {config_name: process_info}
process_lock = Lock()

class MonitorProcessInfo:
    def __init__(self, config_name: str, config_path: str, process: subprocess.Popen):
        self.config_name = config_name
        self.config_path = config_path
        self.process = process
        self.start_time = datetime.now(timezone.utc)
        self.restart_count = 0

class MonitorControlRequest(BaseModel):
    action: str = Field(..., description="Action to perform: start, stop, restart")
    config_name: str = Field(..., description="Configuration name (e.g., 'config.local')")

class MonitorStatus(BaseModel):
    config_name: str
    config_path: str
    is_running: bool
    pid: Optional[int] = None
    start_time: Optional[datetime] = None
    restart_count: int = 0
    memory_usage_mb: Optional[float] = None
    cpu_percent: Optional[float] = None

def get_config_path(config_name: str) -> str:
    """Get the full path to a config file"""
    # Remove .json extension if present
    if config_name.endswith('.json'):
        config_name = config_name[:-5]

    # Add config prefix if not present
    if not config_name.startswith('config.'):
        config_name = f"config.{config_name}"

    # Get project root and construct path
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    config_path = os.path.join(project_root, "monitor", "config", f"{config_name}.json")

    if not os.path.exists(config_path):
        raise HTTPException(status_code=404, detail=f"Config file not found: {config_path}")

    return config_path

def get_monitor_script_path() -> str:
    """Get the path to the run_monitor.sh script"""
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    script_path = os.path.join(project_root, "monitor", "run_monitor.sh")

    if not os.path.exists(script_path):
        raise HTTPException(status_code=500, detail=f"Monitor script not found: {script_path}")

    return script_path

def is_process_running(pid: int) -> bool:
    """Check if a process is still running"""
    try:
        return psutil.pid_exists(pid) and psutil.Process(pid).is_running()
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        return False

def get_process_stats(pid: int) -> Dict[str, Any]:
    """Get process statistics"""
    try:
        process = psutil.Process(pid)
        if not process.is_running():
            return {}

        memory_info = process.memory_info()
        return {
            "memory_usage_mb": memory_info.rss / 1024 / 1024,
            "cpu_percent": process.cpu_percent(interval=0.1)
        }
    except (psutil.NoSuchProcess, psutil.AccessDenied):
        return {}

@monitoring_router.get("/status", response_model=ApiResponse)
async def get_all_monitor_status():
    """Get status of all monitors"""
    try:
        with process_lock:
            statuses = []

            # Clean up dead processes
            dead_configs = []
            for config_name, process_info in monitor_processes.items():
                if not is_process_running(process_info.process.pid):
                    dead_configs.append(config_name)

            for config_name in dead_configs:
                del monitor_processes[config_name]

            # Get status for all running monitors
            for config_name, process_info in monitor_processes.items():
                stats = get_process_stats(process_info.process.pid)

                status = MonitorStatus(
                    config_name=config_name,
                    config_path=process_info.config_path,
                    is_running=True,
                    pid=process_info.process.pid,
                    start_time=process_info.start_time,
                    restart_count=process_info.restart_count,
                    memory_usage_mb=stats.get("memory_usage_mb"),
                    cpu_percent=stats.get("cpu_percent")
                )
                statuses.append(status.dict())

        return ApiResponse(
            success=True,
            message=f"Retrieved status for {len(statuses)} monitors",
            data={"monitors": statuses, "count": len(statuses)}
        )

    except Exception as e:
        logger.error(f"Error getting monitor status: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get monitor status: {str(e)}")

@monitoring_router.get("/status/{config_name}", response_model=ApiResponse)
async def get_monitor_status(config_name: str = Path(..., description="Configuration name")):
    """Get status of a specific monitor"""
    try:
        with process_lock:
            process_info = monitor_processes.get(config_name)

            if not process_info:
                return ApiResponse(
                    success=True,
                    message=f"Monitor '{config_name}' is not running",
                    data={"is_running": False, "config_name": config_name}
                )

            # Check if process is still alive
            if not is_process_running(process_info.process.pid):
                del monitor_processes[config_name]
                return ApiResponse(
                    success=True,
                    message=f"Monitor '{config_name}' is not running",
                    data={"is_running": False, "config_name": config_name}
                )

            stats = get_process_stats(process_info.process.pid)

            status = MonitorStatus(
                config_name=config_name,
                config_path=process_info.config_path,
                is_running=True,
                pid=process_info.process.pid,
                start_time=process_info.start_time,
                restart_count=process_info.restart_count,
                memory_usage_mb=stats.get("memory_usage_mb"),
                cpu_percent=stats.get("cpu_percent")
            )

        return ApiResponse(
            success=True,
            message=f"Status retrieved for monitor '{config_name}'",
            data=status.dict()
        )

    except Exception as e:
        logger.error(f"Error getting monitor status for '{config_name}': {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get monitor status: {str(e)}")

@monitoring_router.post("/control", response_model=ApiResponse)
async def control_monitor(request: MonitorControlRequest):
    """Control monitor: start, stop, or restart"""
    try:
        action = request.action.lower()
        config_name = request.config_name

        if action not in ['start', 'stop', 'restart']:
            raise HTTPException(status_code=400, detail="Action must be 'start', 'stop', or 'restart'")

        with process_lock:
            current_process = monitor_processes.get(config_name)

            # Stop existing process if needed
            if current_process and action in ['stop', 'restart']:
                try:
                    if is_process_running(current_process.process.pid):
                        # Try graceful termination first
                        current_process.process.terminate()

                        # Wait up to 5 seconds for graceful shutdown
                        for _ in range(50):
                            if not is_process_running(current_process.process.pid):
                                break
                            time.sleep(0.1)

                        # Force kill if still running
                        if is_process_running(current_process.process.pid):
                            current_process.process.kill()
                            time.sleep(0.5)

                    del monitor_processes[config_name]
                    logger.info(f"Stopped monitor '{config_name}'")

                except Exception as e:
                    logger.warning(f"Error stopping monitor '{config_name}': {e}")

            # Start process if needed
            if action in ['start', 'restart']:
                if current_process and is_process_running(current_process.process.pid):
                    raise HTTPException(status_code=409, detail=f"Monitor '{config_name}' is already running")

                # Get config path
                config_path = get_config_path(config_name)
                script_path = get_monitor_script_path()

                # Start the monitor process
                logger.info(f"Launching monitor: {script_path} --config {config_path}")
                logger.info(f"Exists script? {os.path.exists(script_path)}")
                logger.info(f"Exists config? {os.path.exists(config_path)}")
                logger.info(f"CWD: {os.getcwd()}")

                try:
                    process = subprocess.Popen(
                        [script_path, "--config", config_path],
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        preexec_fn=os.setsid  # Create new process group
                    )

                    # Wait a moment to check if it started successfully
                    time.sleep(1)
                    if process.poll() is not None:
                        # Process died immediately
                        stdout, stderr = process.communicate()
                        error_msg = stderr.decode() if stderr else stdout.decode()
                        raise HTTPException(status_code=500, detail=f"Monitor failed to start: {error_msg}")

                    # Create process info
                    process_info = MonitorProcessInfo(config_name, config_path, process)
                    if action == 'restart' and current_process:
                        process_info.restart_count = current_process.restart_count + 1

                    monitor_processes[config_name] = process_info

                    logger.info(f"Started monitor '{config_name}' with PID {process.pid}")

                except Exception as e:
                    logger.error(f"Failed to start monitor '{config_name}': {traceback.format_exc()}")
                    raise HTTPException(status_code=500, detail=f"Failed to start monitor: {str(e)}")
        # Return appropriate response
        if action == 'start':
            return ApiResponse(
                success=True,
                message=f"Monitor '{config_name}' started successfully",
                data={"config_name": config_name, "action": action, "pid": process.pid}
            )
        elif action == 'stop':
            return ApiResponse(
                success=True,
                message=f"Monitor '{config_name}' stopped successfully",
                data={"config_name": config_name, "action": action}
            )
        else:  # restart
            return ApiResponse(
                success=True,
                message=f"Monitor '{config_name}' restarted successfully",
                data={"config_name": config_name, "action": action, "pid": process.pid}
            )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error controlling monitor '{request.config_name}': {e}")
        raise HTTPException(status_code=500, detail=f"Failed to control monitor: {str(e)}")

@monitoring_router.post("/start/{config_name}", response_model=ApiResponse)
async def start_monitor(config_name: str = Path(..., description="Configuration name")):
    """Start a specific monitor"""
    request = MonitorControlRequest(action="start", config_name=config_name)
    return await control_monitor(request)

@monitoring_router.post("/stop/{config_name}", response_model=ApiResponse)
async def stop_monitor(config_name: str = Path(..., description="Configuration name")):
    """Stop a specific monitor"""
    request = MonitorControlRequest(action="stop", config_name=config_name)
    return await control_monitor(request)

@monitoring_router.post("/restart/{config_name}", response_model=ApiResponse)
async def restart_monitor(config_name: str = Path(..., description="Configuration name")):
    """Restart a specific monitor"""
    request = MonitorControlRequest(action="restart", config_name=config_name)
    return await control_monitor(request)

@monitoring_router.get("/configs", response_model=ApiResponse)
async def list_available_configs():
    """List all available configuration files"""
    try:
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        config_dir = os.path.join(project_root, "monitor", "config")

        if not os.path.exists(config_dir):
            return ApiResponse(
                success=True,
                message="No config directory found",
                data={"configs": [], "count": 0}
            )

        configs = []
        for filename in os.listdir(config_dir):
            if filename.endswith('.json'):
                config_name = filename[:-5]  # Remove .json extension
                config_path = os.path.join(config_dir, filename)

                # Get file stats
                stat = os.stat(config_path)
                configs.append({
                    "config_name": config_name,
                    "filename": filename,
                    "path": config_path,
                    "size_bytes": stat.st_size,
                    "modified_at": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
                    "is_running": config_name in monitor_processes
                })

        configs.sort(key=lambda x: x["config_name"])

        return ApiResponse(
            success=True,
            message=f"Found {len(configs)} configuration files",
            data={"configs": configs, "count": len(configs)}
        )

    except Exception as e:
        logger.error(f"Error listing configs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list configs: {str(e)}")
