import subprocess
import shlex
from typing import Tuple, Optional
from dataclasses import dataclass
from .config_loader import TargetConfig

@dataclass
class ServiceStatus:
    """Service status result"""
    is_active: bool
    status: str
    error: Optional[str] = None

@dataclass
class ActionResult:
    """Service action result"""
    success: bool
    return_code: int
    stdout: str
    stderr: str

class ServiceChecker:
    """Service status checking and remediation"""

    def __init__(self, timeout: int = 20):
        self.timeout = timeout

    def _shell(self, cmd: str, timeout: int = None) -> subprocess.CompletedProcess:
        """Execute shell command with timeout"""
        timeout = timeout or self.timeout
        return subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )

    def check_service_status(self, target: TargetConfig) -> ServiceStatus:
        """Check service status based on target configuration"""
        try:
            if target.method == "local":
                return self._check_local_status(target.service)
            elif target.method == "ssh":
                return self._check_ssh_status(target)
            else:
                return ServiceStatus(
                    is_active=False,
                    status="unknown",
                    error=f"Unknown method: {target.method}"
                )
        except Exception as e:
            return ServiceStatus(
                is_active=False,
                status="error",
                error=str(e)
            )

    def _check_local_status(self, service: str) -> ServiceStatus:
        """Check local service status"""
        cp = self._shell(f"systemctl is-active {shlex.quote(service)}")
        status = cp.stdout.strip() if cp.returncode in (0, 3) else (
            cp.stdout.strip() or cp.stderr.strip()
        )

        return ServiceStatus(
            is_active=(status == "active"),
            status=status,
            error=cp.stderr.strip() if cp.returncode not in (0, 3) else None
        )

    def _check_ssh_status(self, target: TargetConfig) -> ServiceStatus:
        """Check remote service status via SSH"""
        ssh_config = target.ssh
        user = ssh_config.get("user", "")
        port = ssh_config.get("port", 22)

        cmd = (
            f"ssh -p {port} -o BatchMode=yes -o StrictHostKeyChecking=accept-new "
            f"{shlex.quote(user)}@{shlex.quote(target.host)} "
            f"systemctl is-active {shlex.quote(target.service)}"
        )

        cp = self._shell(cmd, timeout=target.timeout_sec)
        status = cp.stdout.strip() if cp.returncode in (0, 3) else (
            cp.stdout.strip() or cp.stderr.strip()
        )

        return ServiceStatus(
            is_active=(status == "active"),
            status=status,
            error=cp.stderr.strip() if cp.returncode not in (0, 3) else None
        )

    def remediate_service(self, target: TargetConfig) -> ActionResult:
        """Attempt to remediate inactive service"""
        try:
            if target.method == "local":
                return self._remediate_local_service(target)
            elif target.method == "ssh":
                return self._remediate_ssh_service(target)
            else:
                return ActionResult(
                    success=False,
                    return_code=-1,
                    stdout="",
                    stderr=f"Unknown method: {target.method}"
                )
        except Exception as e:
            return ActionResult(
                success=False,
                return_code=-1,
                stdout="",
                stderr=str(e)
            )

    def _remediate_local_service(self, target: TargetConfig) -> ActionResult:
        """Remediate local service"""
        action = "restart" if target.recover_action == "restart" else "start"
        credentials = target.credentials

        # Determine if we need sudo
        use_sudo = target.use_sudo

        # Build the systemctl command
        if use_sudo:
            # Use sudo with credentials if available
            if credentials.get("password"):
                # Use sudo -S to read password from stdin
                cmd = (
                    f"echo {shlex.quote(credentials['password'])} | "
                    f"sudo -S systemctl {action} {shlex.quote(target.service)}"
                )
            else:
                # Use sudo without password (assumes NOPASSWD in sudoers)
                cmd = f"sudo systemctl {action} {shlex.quote(target.service)}"
        else:
            # No sudo - try direct systemctl
            cmd = f"systemctl {action} {shlex.quote(target.service)}"

        cp = self._shell(cmd)

        return ActionResult(
            success=(cp.returncode == 0),
            return_code=cp.returncode,
            stdout=cp.stdout.strip(),
            stderr=cp.stderr.strip()
        )

    def _remediate_ssh_service(self, target: TargetConfig) -> ActionResult:
        """Remediate remote service via SSH"""
        ssh_config = target.ssh
        user = ssh_config.get("user", "")
        port = ssh_config.get("port", 22)
        action = "restart" if target.recover_action == "restart" else "start"
        base = "sudo systemctl" if target.use_sudo else "systemctl"

        cmd = (
            f"ssh -p {port} -o BatchMode=yes -o StrictHostKeyChecking=accept-new "
            f"{shlex.quote(user)}@{shlex.quote(target.host)} "
            f"{base} {action} {shlex.quote(target.service)}"
        )

        cp = self._shell(cmd, timeout=target.timeout_sec)

        return ActionResult(
            success=(cp.returncode == 0),
            return_code=cp.returncode,
            stdout=cp.stdout.strip(),
            stderr=cp.stderr.strip()
        )