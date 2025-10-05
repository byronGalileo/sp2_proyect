# app/api/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.user_service import UserService
from app.schemas.user import UserUpdate, UserResponse
from app.core.authentication import get_current_user
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

@router.put("/profile", response_model=UserResponse)
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