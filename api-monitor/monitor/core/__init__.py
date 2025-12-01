"""
Service Monitor Core Module

Modular service monitoring system with MongoDB logging integration.
"""

from .service_checker import ServiceChecker
from .service_monitor import ServiceMonitor
from .config_loader import ConfigLoader
from .logger_manager import LoggerManager

__all__ = [
    'ServiceChecker',
    'ServiceMonitor',
    'ConfigLoader',
    'LoggerManager'
]

__version__ = "2.0.0"