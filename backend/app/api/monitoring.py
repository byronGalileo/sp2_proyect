# app/api/monitoring.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.services.monitoring_service import MonitoringService
from app.schemas.database_monitoring import ExecuteMonitoringRequest, ExecuteMonitoringResponse, MonitoringResultsList
from app.core.authentication import get_current_user
from app.models.user import User
from app.tasks.monitoring_tasks import execute_monitoring_async

router = APIRouter()

@router.post("/execute/{connection_id}", response_model=ExecuteMonitoringResponse)
async def execute_monitoring(
    connection_id: int,
    request: ExecuteMonitoringRequest = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Execute monitoring for a database connection"""
    async_execution = request.async_execution if request else False

    if async_execution:
        # Execute asynchronously using Celery
        task = execute_monitoring_async.delay(connection_id, current_user.id)
        return ExecuteMonitoringResponse(
            success=True,
            message="Monitoring started asynchronously",
            task_id=task.id
        )
    else:
        # Execute synchronously
        monitoring_service = MonitoringService(db)
        result = monitoring_service.execute_monitoring(connection_id, current_user.id)
        return result

@router.get("/results/{connection_id}", response_model=MonitoringResultsList)
async def get_monitoring_results(
    connection_id: int,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get monitoring results for a database connection"""
    monitoring_service = MonitoringService(db)
    results = monitoring_service.get_monitoring_results(connection_id, current_user.id, skip, limit)

    return MonitoringResultsList(
        results=results,
        total=len(results),  # Approximate count
        connection_id=connection_id
    )