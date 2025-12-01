import time
import sys
import os
from typing import Dict, Any

# Add project root to path for imports
project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from .config_loader import TargetConfig
from .service_checker import ServiceChecker
from .logger_manager import LoggerManager

# Import notification system (optional, won't break if not available)
try:
    from notifications import (
        notification_manager,
        NotificationEventType,
        create_notification_message
    )
    NOTIFICATIONS_AVAILABLE = True
except ImportError:
    NOTIFICATIONS_AVAILABLE = False
    print("Warning: Notification system not available")

class ServiceMonitor:
    """Main service monitoring orchestrator"""

    def __init__(self, logger_manager: LoggerManager):
        self.logger = logger_manager
        self.service_checker = ServiceChecker()
        self.schedule: Dict[int, float] = {}

    def monitor_target(self, target: TargetConfig) -> None:
        """Monitor a single target"""
        # Check if target is enabled
        if not target.active:
            self.logger.info(f"[{target.name}] skip=target_disabled")
            return

        # Extract service type from target name or method
        service_type = "local" if target.method == "local" else "remote"

        # Check service status
        status_result = self.service_checker.check_service_status(target)

        # Log the status check
        self.logger.log_service_status(
            target_name=target.name,
            service_name=target.service,
            status=status_result.status,
            is_active=status_result.is_active,
            host=target.host,
            service_type=service_type,
            metadata={
                'method': target.method,
                'timeout_sec': target.timeout_sec,
                'interval_sec': target.interval_sec
            },
            error=status_result.error
        )

        # Handle remediation if service is not active
        if not status_result.is_active and target.recover_on_down:
            if status_result.error:
                self.logger.warning(f"[{target.name}] Cannot remediate due to status check error: {status_result.error}")
                # Send notification about service down (cannot remediate)
                self._send_notification(
                    target,
                    NotificationEventType.SERVICE_DOWN,
                    metadata={'error': status_result.error}
                )
                return

            self.logger.warning(
                f"[{target.name}] Service '{target.service}' is not active "
                f"(status={status_result.status}). Attempting {target.recover_action}..."
            )

            # Send notification: service restart attempt
            self._send_notification(
                target,
                NotificationEventType.SERVICE_RESTART_ATTEMPT,
                metadata={'action': target.recover_action, 'status': status_result.status}
            )

            # Attempt remediation
            remediation_result = self.service_checker.remediate_service(target)

            # Log remediation result
            self.logger.log_remediation_attempt(
                target_name=target.name,
                service_name=target.service,
                action=target.recover_action,
                success=remediation_result.success,
                host=target.host,
                service_type=service_type,
                metadata={
                    'return_code': remediation_result.return_code,
                    'stdout': remediation_result.stdout,
                    'stderr': remediation_result.stderr,
                    'use_sudo': target.use_sudo,
                    'method': target.method
                },
                error_details=remediation_result.stderr if not remediation_result.success else None
            )

            # Send notification based on remediation result
            if remediation_result.success:
                self._send_notification(
                    target,
                    NotificationEventType.SERVICE_RECOVERED,
                    metadata={'action': target.recover_action}
                )
            else:
                self._send_notification(
                    target,
                    NotificationEventType.SERVICE_RESTART_FAILED,
                    metadata={
                        'action': target.recover_action,
                        'error': remediation_result.stderr or 'Unknown error',
                        'return_code': remediation_result.return_code
                    }
                )

        elif not status_result.is_active and not target.recover_on_down:
            self.logger.warning(f"[{target.name}] Service not active but recovery is disabled")
            # Send notification: service down (recovery disabled)
            self._send_notification(
                target,
                NotificationEventType.SERVICE_DOWN,
                metadata={'recovery_disabled': True}
            )

    def _send_notification(
        self,
        target: TargetConfig,
        event_type: 'NotificationEventType',
        metadata: Dict[str, Any] = None
    ) -> None:
        """Send notification for service event"""
        if not NOTIFICATIONS_AVAILABLE:
            return

        try:
            # Create notification message
            message = create_notification_message(
                event_type,
                target.service,
                target.host,
                metadata
            )

            # Send notification
            notification_manager.send_service_notification(
                service_name=target.service,
                host=target.host,
                event_type=event_type,
                message=message,
                metadata=metadata
            )
        except Exception as e:
            self.logger.error(f"Failed to send notification for {target.service}: {e}")

    def initialize_schedule(self, targets: list) -> None:
        """Initialize monitoring schedule for all targets"""
        now = time.time()
        for target in targets:
            self.schedule[id(target)] = now  # Execute immediately

    def should_monitor_target(self, target: TargetConfig) -> bool:
        """Check if it's time to monitor this target"""
        now = time.time()
        key = id(target)
        next_run = self.schedule.get(key, now)

        if now >= next_run:
            # Schedule next run
            self.schedule[key] = now + target.interval_sec
            return True

        return False

    def run_monitoring_cycle(self, targets: list) -> None:
        """Run one complete monitoring cycle"""
        for target in targets:
            if self.should_monitor_target(target):
                try:
                    self.monitor_target(target)
                except Exception as e:
                    self.logger.error(f"[{target.name}] Unexpected error during monitoring: {e}")

    def run_once(self, targets: list) -> None:
        """Run monitoring once for all targets"""
        for target in targets:
            try:
                self.monitor_target(target)
            except Exception as e:
                self.logger.error(f"[{target.name}] Unexpected error during monitoring: {e}")

    def run_continuous(self, targets: list, sleep_interval: int = 1) -> None:
        """Run continuous monitoring loop"""
        self.initialize_schedule(targets)
        self.logger.log_monitor_start(
            len(targets),
            {
                'sleep_interval': sleep_interval,
                'targets': [{'name': t.name, 'service': t.service, 'interval': t.interval_sec} for t in targets]
            }
        )

        try:
            while True:
                self.run_monitoring_cycle(targets)
                time.sleep(sleep_interval)
        except KeyboardInterrupt:
            self.logger.log_monitor_stop("user_interrupt")
        except Exception as e:
            self.logger.error(f"Monitor loop failed: {e}")
            self.logger.log_monitor_stop(f"error: {e}")
            raise