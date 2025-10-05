# app/services/monitoring_service.py
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.services.database_service import DatabaseService
from app.schemas.database_monitoring import ExecuteMonitoringResponse

class MonitoringService:
    """Service for database monitoring operations"""

    def __init__(self, db: Session):
        self.db = db
        self.database_service = DatabaseService(db)

    def execute_monitoring(self, connection_id: int, user_id: int) -> ExecuteMonitoringResponse:
        """Execute monitoring for a database connection"""
        return self.database_service.execute_monitoring(connection_id, user_id)

    def get_monitoring_results(self, connection_id: int, user_id: int, skip: int = 0, limit: int = 50):
        """Get monitoring results for a connection"""
        return self.database_service.get_monitoring_results(connection_id, user_id, skip, limit)