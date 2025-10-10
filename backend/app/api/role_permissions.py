# app/api/role_permissions.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.services.role_permission_service import RolePermissionService
from app.schemas.role_permission import (
    RolePermissionCreate,
    RolePermissionUpdate,
    RolePermissionResponse,
    RolePermissionListResponse
)
from app.core.authentication import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("", response_model=List[RolePermissionListResponse])
async def get_all_role_permissions(
    role_id: Optional[int] = Query(None, description="Filter by role ID"),
    permission_id: Optional[int] = Query(None, description="Filter by permission ID"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all role-permission assignments with optional filters"""
    role_permission_service = RolePermissionService(db)

    if role_id:
        role_permissions = role_permission_service.get_by_role_id(role_id)
    elif permission_id:
        role_permissions = role_permission_service.get_by_permission_id(permission_id)
    else:
        role_permissions = role_permission_service.get_all()

    return role_permissions

@router.get("/{role_permission_id}", response_model=RolePermissionResponse)
async def get_role_permission(
    role_permission_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific role-permission assignment by ID"""
    role_permission_service = RolePermissionService(db)
    role_permission = role_permission_service.get_by_id(role_permission_id)

    if not role_permission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Role-Permission assignment with ID {role_permission_id} not found"
        )

    return role_permission

@router.post("", response_model=RolePermissionResponse, status_code=status.HTTP_201_CREATED)
async def create_role_permission(
    role_permission_data: RolePermissionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Assign a permission to a role"""
    role_permission_service = RolePermissionService(db)

    try:
        new_role_permission = role_permission_service.create_role_permission(role_permission_data)
        return new_role_permission
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/{role_permission_id}", response_model=RolePermissionResponse)
async def update_role_permission(
    role_permission_id: int,
    role_permission_data: RolePermissionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a role-permission assignment"""
    role_permission_service = RolePermissionService(db)

    try:
        updated_role_permission = role_permission_service.update_role_permission(
            role_permission_id, role_permission_data
        )

        if not updated_role_permission:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Role-Permission assignment with ID {role_permission_id} not found"
            )

        return updated_role_permission
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
