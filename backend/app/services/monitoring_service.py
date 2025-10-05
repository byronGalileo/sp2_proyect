# app/services/monitoring_service.py
import sys
import os
from typing import Dict, Any

# Import your existing monitoring classes
# Add your framework directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import your existing monitor classes
from your_monitor_framework import SQLServerMonitor, MySQLMonitor, PostgreSQLMonitor

class MonitoringService:
    """Service to integrate your existing monitoring framework"""
    
    @staticmethod
    def get_monitor_class(db_type: str):
        """Get the appropriate monitor class"""
        monitors = {
            'mysql': MySQLMonitor,
            'postgresql': PostgreSQLMonitor,
            'sqlserver': SQLServerMonitor
        }
        return monitors.get(db_type.lower())
    
    @staticmethod
    def execute_monitoring(connection_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute monitoring using your existing framework"""
        try:
            monitor_class = MonitoringService.get_monitor_class(connection_data['db_type'])
            if not monitor_class:
                return {"status": "error", "error": "Unsupported database type"}
            
            # Create monitor instance
            monitor = monitor_class(
                server=connection_data['hostname'],
                database=connection_data['database_name'],
                username=connection_data['username'],
                password=connection_data['password'],  # This should be decrypted
                port=connection_data['port']
            )
            
            # Execute monitoring
            result = monitor.monitor()
            return result
            
        except Exception as e:
            return {
                "status": "error",
                "error": str(e),
                "error_type": type(e).__name__
            }