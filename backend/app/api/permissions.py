# app/api/permissions.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.services.permission_service import PermissionService
from app.schemas.permission import PermissionCreate, PermissionUpdate, PermissionResponse
from app.core.authentication import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("", response_model=List[PermissionResponse])
async def get_all_permissions(
    include_inactive: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all permissions"""
    permission_service = PermissionService(db)
    permissions = permission_service.get_all(include_inactive=include_inactive)
    return permissions

@router.get("/{permission_id}", response_model=PermissionResponse)
async def get_permission(
    permission_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific permission by ID"""
    permission_service = PermissionService(db)
    permission = permission_service.get_by_id(permission_id)

    if not permission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Permission with ID {permission_id} not found"
        )

    return permission

@router.post("", response_model=PermissionResponse, status_code=status.HTTP_201_CREATED)
async def create_permission(
    permission_data: PermissionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new permission"""
    permission_service = PermissionService(db)

    try:
        new_permission = permission_service.create_permission(permission_data)
        return new_permission
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/{permission_id}", response_model=PermissionResponse)
async def update_permission(
    permission_id: int,
    permission_data: PermissionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update an existing permission"""
    permission_service = PermissionService(db)

    try:
        updated_permission = permission_service.update_permission(permission_id, permission_data)

        if not updated_permission:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Permission with ID {permission_id} not found"
            )

        return updated_permission
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
