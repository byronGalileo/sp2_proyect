# app/tasks/monitoring_tasks.py
from app.tasks.celery_app import celery_app
from app.database import SessionLocal
from app.services.monitoring_service import MonitoringService
from app.schemas.database_monitoring import ExecuteMonitoringResponse

@celery_app.task(bind=True)
def execute_monitoring_async(self, connection_id: int, user_id: int):
    """Execute monitoring asynchronously"""
    db = SessionLocal()
    try:
        monitoring_service = MonitoringService(db)
        result = monitoring_service.execute_monitoring(connection_id, user_id)
        return result.model_dump()
    finally:
        db.close()