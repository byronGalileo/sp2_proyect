# app/tasks/celery_app.py
from celery import Celery
from app.config import settings

# Create Celery app
celery_app = Celery(
    "monitoring_system",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.tasks.monitoring_tasks"]
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_routes={
        "app.tasks.monitoring_tasks.execute_monitoring_async": {"queue": "monitoring"},
    },
)

# Optional: Configure task result expiration
celery_app.conf.result_expires = 3600  # 1 hour