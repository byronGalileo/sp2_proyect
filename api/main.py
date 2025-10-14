#!/usr/bin/env python3
"""
Service Monitor API - Main Application

FastAPI application for exposing service monitoring statistics and managing
log delivery status. Provides endpoints to:

1. Get service statistics
2. Get unsent logs
3. Mark logs as sent to users
4. Get service health summary
"""

import os
import sys
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any
import logging

# Setup Python path for imports
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
venv_path = os.path.join(project_root, "venv")
venv_site_packages = os.path.join(venv_path, "lib", f"python{sys.version_info.major}.{sys.version_info.minor}", "site-packages")

if os.path.exists(venv_site_packages):
    sys.path.insert(0, venv_site_packages)
sys.path.insert(0, project_root)

from fastapi import FastAPI, HTTPException, Query, Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn

from database import log_operations, LogLevel
from api.routers import hosts_router, services_router, config_router, monitoring_router

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(
    title="Service Monitor API",
    description="REST API for service monitoring statistics and log management",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Include new routers
app.include_router(hosts_router)
app.include_router(services_router)
app.include_router(config_router)
app.include_router(monitoring_router)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure as needed for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class LogEntry(BaseModel):
    id: str = Field(..., description="Log entry ID")
    service_name: str = Field(..., description="Service name")
    service_type: str = Field(..., description="Service type (local/remote)")
    host: str = Field(..., description="Host name")
    log_level: str = Field(..., description="Log level")
    message: str = Field(..., description="Log message")
    timestamp: datetime = Field(..., description="Log timestamp")
    status: Optional[str] = Field(None, description="Service status")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")
    tags: List[str] = Field(default_factory=list, description="Log tags")
    sent_to_user: bool = Field(..., description="Whether log has been sent to user")

class ServiceSummary(BaseModel):
    service_name: str = Field(..., description="Service name")
    total_logs: int = Field(..., description="Total number of logs")
    unsent_logs: int = Field(..., description="Number of unsent logs")
    latest_timestamp: Optional[datetime] = Field(None, description="Latest log timestamp")
    latest_status: Optional[str] = Field(None, description="Latest service status")
    latest_level: Optional[str] = Field(None, description="Latest log level")
    service_type: Optional[str] = Field(None, description="Service type")
    host: Optional[str] = Field(None, description="Host name")

class ApiResponse(BaseModel):
    success: bool = Field(..., description="Whether the operation was successful")
    message: str = Field(..., description="Response message")
    data: Optional[Any] = Field(None, description="Response data")

class MarkSentRequest(BaseModel):
    log_ids: List[str] = Field(..., description="List of log IDs to mark as sent")

# Health check endpoint
@app.get("/", response_model=Dict[str, Any])
async def root():
    """Root endpoint with API information"""
    return {
        "name": "Service Monitor API",
        "version": "2.0.0",
        "description": "REST API for service monitoring statistics, log management, and host/service configuration",
        "endpoints": {
            "health": "/health",
            "statistics": "/stats",
            "logs": "/logs",
            "unsent_logs": "/logs/unsent",
            "mark_sent": "/logs/mark-sent",
            "hosts": "/hosts",
            "services": "/services",
            "config_generation": "/config/generate",
            "config_download": "/config/download",
            "monitor_status": "/monitoring/status",
            "monitor_control": "/monitoring/control",
            "monitor_configs": "/monitoring/configs",
            "documentation": "/docs"
        }
    }

@app.get("/health", response_model=Dict[str, Any])
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        connection_healthy = log_operations.connection.health_check()

        return {
            "status": "healthy" if connection_healthy else "unhealthy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "database": {
                "connected": connection_healthy,
                "database_name": log_operations.connection.config.database_name,
                "collections": {
                    "logs": log_operations.connection.config.logs_collection,
                    "events": log_operations.connection.config.events_collection
                }
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

# Statistics endpoints
@app.get("/stats", response_model=Dict[str, Any])
async def get_general_statistics():
    """Get general monitoring statistics"""
    try:
        # Get service summary
        summary = log_operations.get_service_summary()

        # Get recent error logs count
        error_logs = log_operations.get_error_logs(hours=24)

        # Calculate additional stats
        stats = {
            "total_services": summary.get('total_services', 0),
            "total_unsent_logs": sum(service.get('unsent_logs', 0) for service in summary.get('services', [])),
            "total_logs_24h": sum(service.get('total_logs', 0) for service in summary.get('services', [])),
            "error_logs_24h": len(error_logs),
            "last_updated": summary.get('last_updated'),
            "services": summary.get('services', [])
        }

        return stats

    except Exception as e:
        logger.error(f"Error getting statistics: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")

@app.get("/stats/{service_name}", response_model=Dict[str, Any])
async def get_service_statistics(
    service_name: str = Path(..., description="Service name"),
    hours: int = Query(24, ge=1, le=168, description="Hours to look back (1-168)")
):
    """Get statistics for a specific service"""
    try:
        stats = log_operations.get_service_statistics(service_name, hours=hours)

        if not stats:
            raise HTTPException(status_code=404, detail=f"No data found for service: {service_name}")

        return stats

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting service statistics: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get service statistics: {str(e)}")

# Services endpoints
@app.get("/services", response_model=Dict[str, Any])
async def get_services_summary():
    """Get summary of all monitored services"""
    try:
        summary = log_operations.get_service_summary()
        return summary

    except Exception as e:
        logger.error(f"Error getting services summary: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get services summary: {str(e)}")

# Logs endpoints
@app.get("/logs", response_model=Dict[str, Any])
async def get_logs(
    service_name: Optional[str] = Query(None, description="Filter by service name"),
    log_level: Optional[str] = Query(None, description="Filter by log level"),
    hours: int = Query(24, ge=1, le=168, description="Hours to look back"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of logs to return")
):
    """Get logs with optional filters"""
    try:
        # Convert log_level string to LogLevel enum if provided
        level_filter = None
        if log_level:
            try:
                level_filter = LogLevel(log_level.upper())
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid log level: {log_level}")

        # Get logs
        if service_name:
            logs = log_operations.get_recent_logs(service_name, hours=hours, limit=limit)
        else:
            end_time = datetime.now(timezone.utc)
            start_time = end_time - timedelta(hours=hours)
            logs = log_operations.get_logs(
                log_level=level_filter,
                start_time=start_time,
                end_time=end_time,
                limit=limit
            )

        # Convert ObjectId to string for JSON serialization
        for log in logs:
            if '_id' in log:
                log['id'] = str(log['_id'])
                del log['_id']

        return {
            "total": len(logs),
            "logs": logs,
            "filters": {
                "service_name": service_name,
                "log_level": log_level,
                "hours": hours,
                "limit": limit
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting logs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get logs: {str(e)}")

@app.get("/logs/unsent", response_model=Dict[str, Any])
async def get_unsent_logs(
    service_name: Optional[str] = Query(None, description="Filter by service name"),
    log_level: Optional[str] = Query(None, description="Filter by log level"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of logs to return")
):
    """Get logs that haven't been sent to users yet"""
    try:
        # Convert log_level string to LogLevel enum if provided
        level_filter = None
        if log_level:
            try:
                level_filter = LogLevel(log_level.upper())
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid log level: {log_level}")

        # Get unsent logs
        logs = log_operations.get_unsent_logs(
            service_name=service_name,
            log_level=level_filter,
            limit=limit
        )

        # Convert ObjectId to string for JSON serialization
        for log in logs:
            if '_id' in log:
                log['id'] = str(log['_id'])
                del log['_id']

        return {
            "total": len(logs),
            "logs": logs,
            "filters": {
                "service_name": service_name,
                "log_level": log_level,
                "limit": limit
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting unsent logs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get unsent logs: {str(e)}")

@app.post("/logs/mark-sent", response_model=ApiResponse)
async def mark_logs_as_sent(request: MarkSentRequest):
    """Mark specified logs as sent to users"""
    try:
        if not request.log_ids:
            raise HTTPException(status_code=400, detail="No log IDs provided")

        # Mark logs as sent
        updated_count = log_operations.mark_logs_as_sent(request.log_ids)

        return ApiResponse(
            success=True,
            message=f"Marked {updated_count} logs as sent",
            data={
                "requested": len(request.log_ids),
                "updated": updated_count,
                "log_ids": request.log_ids
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error marking logs as sent: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to mark logs as sent: {str(e)}")

# Main entry point
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Service Monitor API")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8000, help="Port to bind to")
    parser.add_argument("--reload", action="store_true", help="Enable auto-reload for development")

    args = parser.parse_args()

    print(f"🚀 Starting Service Monitor API on {args.host}:{args.port}")
    print(f"📚 API Documentation: http://{args.host}:{args.port}/docs")

    uvicorn.run(
        "main:app",
        host=args.host,
        port=args.port,
        reload=args.reload,
        log_level="info"
    )