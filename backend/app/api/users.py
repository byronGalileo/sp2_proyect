# app/api/users.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.services.user_service import UserService
from app.schemas.user import (
    UserUpdate, UserResponse, UsersListResponse, UserListResponse,
    UserAdminUpdate, UserRoleAssignment, UserPasswordReset, UserCreate
)
from app.core.authentication import get_current_user, require_role
from app.models.user import User

router = APIRouter()

@router.get("/profile", response_model=UserResponse)
async def get_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current user profile"""
    user_service = UserService(db)
    user_profile = user_service.get_user_with_permissions(current_user.id)

    if not user_profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found"
        )

    return user_profile

@router.post("/profile", response_model=UserResponse)
async def update_profile(
    update_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update current user profile"""
    user_service = UserService(db)

    # Get current user data
    current_user_data = user_service.get_by_id(current_user.id)
    if not current_user_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Update fields
    update_dict = update_data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(current_user_data, field, value)

    db.commit()
    db.refresh(current_user_data)

    # Return updated profile with permissions
    return user_service.get_user_with_permissions(current_user.id)

# =============== ADMIN ENDPOINTS ===============

@router.get("/", response_model=UsersListResponse)
async def get_all_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    is_active: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Get all users (Admin only)"""
    user_service = UserService(db)
    users, total = user_service.get_all_users(skip=skip, limit=limit, is_active=is_active)

    # Convert users to response format
    user_list = []
    for user in users:
        roles = [role.name for role in user.roles]
        user_list.append(UserListResponse(
            id=user.id,
            username=user.username,
            email=user.email,
            first_name=user.first_name,
            last_name=user.last_name,
            is_active=user.is_active,
            email_verified=user.email_verified,
            last_login_at=user.last_login_at,
            created_at=user.created_at,
            roles=roles
        ))

    return UsersListResponse(
        users=user_list,
        total=total,
        skip=skip,
        limit=limit
    )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user_by_id(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Get user by ID (Admin only)"""
    user_service = UserService(db)
    user_profile = user_service.get_user_with_permissions(user_id)

    if not user_profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user_profile

@router.post("/create", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Create a new user (Admin only)"""
    user_service = UserService(db)

    # Check if username already exists
    if user_service.get_by_username(user_data.username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )

    # Check if email already exists
    if user_service.get_by_email(user_data.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create user
    new_user = user_service.create_user(user_data)

    return user_service.get_user_with_permissions(new_user.id)

@router.post("/{user_id}/update", response_model=UserResponse)
async def update_user(
    user_id: int,
    update_data: UserAdminUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Update user data (Admin only)"""
    user_service = UserService(db)

    # Check if user exists
    user = user_service.get_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Check for unique constraints if updating username or email
    update_dict = update_data.model_dump(exclude_unset=True)

    if 'username' in update_dict:
        existing_user = user_service.get_by_username(update_dict['username'])
        if existing_user and existing_user.id != user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )

    if 'email' in update_dict:
        existing_user = user_service.get_by_email(update_dict['email'])
        if existing_user and existing_user.id != user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already taken"
            )

    # Update user
    updated_user = user_service.update_user(user_id, update_dict)

    return user_service.get_user_with_permissions(updated_user.id)

@router.post("/{user_id}/deactivate", response_model=UserResponse)
async def deactivate_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Deactivate a user (Admin only)"""
    user_service = UserService(db)

    # Prevent self-deactivation
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate your own account"
        )

    user = user_service.deactivate_user(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user_service.get_user_with_permissions(user.id)

@router.post("/{user_id}/activate", response_model=UserResponse)
async def activate_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Activate a user (Admin only)"""
    user_service = UserService(db)

    user = user_service.activate_user(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user_service.get_user_with_permissions(user.id)

@router.post("/{user_id}/assign-roles", response_model=UserResponse)
async def assign_roles_to_user(
    user_id: int,
    role_data: UserRoleAssignment,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Assign roles to a user (Admin only)"""
    user_service = UserService(db)

    user = user_service.assign_roles(user_id, role_data.role_ids)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user_service.get_user_with_permissions(user.id)

@router.post("/{user_id}/reset-password", response_model=UserResponse)
async def reset_user_password(
    user_id: int,
    password_data: UserPasswordReset,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role("admin", "super_admin"))
):
    """Reset user password (Admin only)"""
    user_service = UserService(db)

    user = user_service.reset_password(user_id, password_data.new_password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return user_service.get_user_with_permissions(user.id)