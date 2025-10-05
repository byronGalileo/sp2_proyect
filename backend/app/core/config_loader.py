import json
import os
from typing import Dict, Any, List
from dataclasses import dataclass, field

@dataclass
class TargetConfig:
    """Configuration for a monitoring target"""
    name: str
    service: str
    method: str = "local"
    host: str = "localhost"
    active: bool = True
    interval_sec: int = 60
    timeout_sec: int = 20
    recover_on_down: bool = True
    recover_action: str = "start"
    use_sudo: bool = False
    ssh: Dict[str, Any] = field(default_factory=dict)
    credentials: Dict[str, str] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TargetConfig':
        """Create TargetConfig from dictionary"""
        # Set default name if not provided
        if "name" not in data:
            data["name"] = f"{data.get('host', 'local')}-{data.get('service', 'unknown')}"

        return cls(**{k: v for k, v in data.items() if k in cls.__dataclass_fields__})

@dataclass
class MonitorConfig:
    """Main monitor configuration"""
    log_file: str = "logs/service_monitor.log"
    log_level: str = "INFO"
    targets: List[TargetConfig] = field(default_factory=list)
    mongodb: Dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'MonitorConfig':
        """Create MonitorConfig from dictionary"""
        targets = [TargetConfig.from_dict(t) for t in data.get("targets", [])]
        return cls(
            log_file=data.get("log_file", "logs/service_monitor.log"),
            log_level=data.get("log_level", "INFO"),
            targets=targets,
            mongodb=data.get("mongodb", {})
        )

class ConfigLoader:
    """Configuration loader and validator"""

    @staticmethod
    def load(config_path: str) -> MonitorConfig:
        """Load and validate configuration from file"""
        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Configuration file not found: {config_path}")

        try:
            with open(config_path, 'r') as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON in configuration file: {e}")

        config = MonitorConfig.from_dict(data)
        ConfigLoader._validate_config(config)
        return config

    @staticmethod
    def _validate_config(config: MonitorConfig) -> None:
        """Validate configuration"""
        if not config.targets:
            raise ValueError("No targets defined in configuration")

        for target in config.targets:
            if not target.service:
                raise ValueError(f"Target '{target.name}' missing service name")

            if target.method not in ["local", "ssh"]:
                raise ValueError(f"Invalid method '{target.method}' for target '{target.name}'")

            if target.method == "ssh" and not target.host:
                raise ValueError(f"SSH target '{target.name}' missing host")

            if target.interval_sec < 1:
                raise ValueError(f"Target '{target.name}' interval_sec must be >= 1")

    @staticmethod
    def create_example_config(path: str) -> None:
        """Create an example configuration file"""
        example_config = {
            "log_file": "logs/service_monitor.log",
            "log_level": "INFO",
            "mongodb": {
                "enabled": True,
                "host": "localhost",
                "port": 27017,
                "database": "service_monitoring"
            },
            "targets": [
                {
                    "name": "local-prometheus",
                    "service": "prometheus.service",
                    "method": "local",
                    "active": True,
                    "interval_sec": 30,
                    "recover_on_down": True,
                    "recover_action": "restart",
                    "use_sudo": False
                },
                {
                    "name": "remote-mysql",
                    "service": "mysql.service",
                    "method": "ssh",
                    "host": "10.10.0.15",
                    "active": True,
                    "interval_sec": 60,
                    "ssh": {
                        "user": "svcctl",
                        "port": 22
                    },
                    "recover_on_down": True,
                    "recover_action": "restart",
                    "use_sudo": True
                }
            ]
        }

        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w') as f:
            json.dump(example_config, f, indent=2)