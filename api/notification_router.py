#!/usr/bin/env python3
"""
Notification API Router

Provides endpoints for managing notification configurations and sending notifications.
"""

import sys
import os
from typing import List, Optional, Dict, Any
from datetime import datetime

# Setup Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

from fastapi import APIRouter, HTTPException, Query, Path, Body
from pydantic import BaseModel, Field

from notifications import (
    notification_manager,
    notification_operations,
    NotificationChannel,
    NotificationEventType,
    NotificationStatus,
    NotificationContact,
    ServiceNotificationConfig,
    create_notification_message
)


# Create router
router = APIRouter(prefix="/notifications", tags=["notifications"])


# Pydantic models for API
class ContactModel(BaseModel):
    name: str = Field(..., description="Contact name")
    phone: Optional[str] = Field(None, description="Phone number in E.164 format (e.g., +50212345678)")
    email: Optional[str] = Field(None, description="Email address")
    enabled: bool = Field(True, description="Whether contact is enabled")
    channels: List[str] = Field(default=["sms"], description="Notification channels (sms, email, push)")
    notify_on: List[str] = Field(
        default=["service_down", "service_restart_attempt", "service_restart_failed", "service_recovered"],
        description="Events to notify about"
    )


class NotificationConfigRequest(BaseModel):
    service_name: str = Field(..., description="Service name")
    host: str = Field(..., description="Host where service runs")
    contacts: List[ContactModel] = Field(..., description="List of contacts to notify")
    enabled: bool = Field(True, description="Whether notifications are enabled")
    cooldown_minutes: int = Field(5, ge=1, le=60, description="Cooldown period between notifications (1-60 minutes)")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")


class SendNotificationRequest(BaseModel):
    service_name: str = Field(..., description="Service name")
    host: str = Field(..., description="Host where service runs")
    event_type: str = Field(..., description="Event type (service_down, service_restart_attempt, etc.)")
    message: Optional[str] = Field(None, description="Custom message (auto-generated if not provided)")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")


class TestSMSRequest(BaseModel):
    phone_number: str = Field(..., description="Phone number in E.164 format (e.g., +50212345678)")
    message: str = Field(default="Test notification from Service Monitor", description="Test message")


class ApiResponse(BaseModel):
    success: bool = Field(..., description="Whether operation was successful")
    message: str = Field(..., description="Response message")
    data: Optional[Any] = Field(None, description="Response data")


# Endpoints

@router.get("/status", response_model=Dict[str, Any])
async def get_notification_service_status():
    """Get status of notification services (SMS, Email, Push)"""
    return notification_manager.get_service_status()


@router.get("/configs", response_model=Dict[str, Any])
async def get_all_notification_configs(
    enabled_only: bool = Query(False, description="Only return enabled configurations")
):
    """Get all notification configurations"""
    try:
        configs = notification_operations.get_all_notification_configs(enabled_only=enabled_only)

        return {
            "total": len(configs),
            "configs": [
                {
                    "service_name": config.service_name,
                    "host": config.host,
                    "enabled": config.enabled,
                    "cooldown_minutes": config.cooldown_minutes,
                    "contacts": [c.to_dict() for c in config.contacts],
                    "metadata": config.metadata
                }
                for config in configs
            ]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification configs: {str(e)}")


@router.get("/configs/{service_name}", response_model=Dict[str, Any])
async def get_notification_config(
    service_name: str = Path(..., description="Service name"),
    host: str = Query(..., description="Host name")
):
    """Get notification configuration for a specific service"""
    try:
        config = notification_operations.get_notification_config(service_name, host)

        if not config:
            raise HTTPException(
                status_code=404,
                detail=f"No notification configuration found for {host}:{service_name}"
            )

        return {
            "service_name": config.service_name,
            "host": config.host,
            "enabled": config.enabled,
            "cooldown_minutes": config.cooldown_minutes,
            "contacts": [c.to_dict() for c in config.contacts],
            "metadata": config.metadata
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification config: {str(e)}")


@router.post("/configs", response_model=ApiResponse)
async def create_notification_config(request: NotificationConfigRequest):
    """Create or update notification configuration for a service"""
    try:
        # Convert request to domain model
        contacts = []
        for contact_data in request.contacts:
            contact = NotificationContact(
                name=contact_data.name,
                phone=contact_data.phone,
                email=contact_data.email,
                enabled=contact_data.enabled,
                channels=[NotificationChannel(ch) for ch in contact_data.channels],
                notify_on=[NotificationEventType(ev) for ev in contact_data.notify_on]
            )
            contacts.append(contact)

        config = ServiceNotificationConfig(
            service_name=request.service_name,
            host=request.host,
            contacts=contacts,
            enabled=request.enabled,
            cooldown_minutes=request.cooldown_minutes,
            metadata=request.metadata
        )

        # Save to database
        success = notification_operations.save_notification_config(config)

        if not success:
            raise HTTPException(status_code=500, detail="Failed to save notification configuration")

        return ApiResponse(
            success=True,
            message=f"Notification configuration saved for {request.host}:{request.service_name}",
            data={
                "service_name": request.service_name,
                "host": request.host,
                "contacts_count": len(contacts)
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create notification config: {str(e)}")


@router.put("/configs/{service_name}/status", response_model=ApiResponse)
async def update_notification_config_status(
    service_name: str = Path(..., description="Service name"),
    host: str = Query(..., description="Host name"),
    enabled: bool = Query(..., description="Enable or disable notifications")
):
    """Enable or disable notifications for a service"""
    try:
        success = notification_operations.update_notification_config_status(service_name, host, enabled)

        if not success:
            raise HTTPException(
                status_code=404,
                detail=f"No notification configuration found for {host}:{service_name}"
            )

        return ApiResponse(
            success=True,
            message=f"Notifications {'enabled' if enabled else 'disabled'} for {host}:{service_name}",
            data={
                "service_name": service_name,
                "host": host,
                "enabled": enabled
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update notification status: {str(e)}")


@router.delete("/configs/{service_name}", response_model=ApiResponse)
async def delete_notification_config(
    service_name: str = Path(..., description="Service name"),
    host: str = Query(..., description="Host name")
):
    """Delete notification configuration for a service"""
    try:
        success = notification_operations.delete_notification_config(service_name, host)

        if not success:
            raise HTTPException(
                status_code=404,
                detail=f"No notification configuration found for {host}:{service_name}"
            )

        return ApiResponse(
            success=True,
            message=f"Notification configuration deleted for {host}:{service_name}",
            data={
                "service_name": service_name,
                "host": host
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete notification config: {str(e)}")


@router.post("/send", response_model=Dict[str, Any])
async def send_notification(request: SendNotificationRequest):
    """Manually send a notification for a service event"""
    try:
        # Validate event type
        try:
            event_type = NotificationEventType(request.event_type)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid event type: {request.event_type}. "
                       f"Valid types: {[e.value for e in NotificationEventType]}"
            )

        # Generate message if not provided
        message = request.message
        if not message:
            message = create_notification_message(
                event_type,
                request.service_name,
                request.host,
                request.metadata
            )

        # Send notification
        result = notification_manager.send_service_notification(
            service_name=request.service_name,
            host=request.host,
            event_type=event_type,
            message=message,
            metadata=request.metadata
        )

        return {
            "success": result['sent'] > 0,
            "message": f"Sent {result['sent']} notifications, {result['failed']} failed, {result['skipped']} skipped",
            "data": result
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send notification: {str(e)}")


@router.post("/test/sms", response_model=ApiResponse)
async def test_sms_notification(request: TestSMSRequest):
    """Send a test SMS notification"""
    try:
        result = notification_manager.send_test_notification(
            phone_number=request.phone_number,
            message=request.message
        )

        if not result['success']:
            return ApiResponse(
                success=False,
                message=f"Failed to send test SMS: {result.get('error')}",
                data=result
            )

        return ApiResponse(
            success=True,
            message=f"Test SMS sent successfully to {request.phone_number}",
            data=result
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send test SMS: {str(e)}")


@router.get("/history", response_model=Dict[str, Any])
async def get_notification_history(
    service_name: Optional[str] = Query(None, description="Filter by service name"),
    host: Optional[str] = Query(None, description="Filter by host"),
    event_type: Optional[str] = Query(None, description="Filter by event type"),
    status: Optional[str] = Query(None, description="Filter by status (sent, failed, pending)"),
    hours: int = Query(24, ge=1, le=168, description="Hours to look back (1-168)"),
    limit: int = Query(100, ge=1, le=1000, description="Maximum number of records")
):
    """Get notification history with optional filters"""
    try:
        # Convert string filters to enums
        event_filter = NotificationEventType(event_type) if event_type else None
        status_filter = NotificationStatus(status) if status else None

        # Get history
        history = notification_operations.get_notification_history(
            service_name=service_name,
            host=host,
            event_type=event_filter,
            status=status_filter,
            hours=hours,
            limit=limit
        )

        return {
            "total": len(history),
            "history": history,
            "filters": {
                "service_name": service_name,
                "host": host,
                "event_type": event_type,
                "status": status,
                "hours": hours,
                "limit": limit
            }
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid filter value: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification history: {str(e)}")


@router.get("/stats", response_model=Dict[str, Any])
async def get_notification_stats(
    hours: int = Query(24, ge=1, le=168, description="Hours to analyze (1-168)")
):
    """Get notification statistics"""
    try:
        stats = notification_operations.get_notification_stats(hours=hours)
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get notification stats: {str(e)}")
