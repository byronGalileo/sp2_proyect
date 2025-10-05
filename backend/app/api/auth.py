# app/api/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

from app.database import get_db
from app.models.user import User, Role
from app.schemas.auth import UserCreate, UserLogin, UserResponse, Token, AuthResponse
from app.schemas.common import StandardResponse
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token
from app.services.user_service import UserService
from app.config import settings

router = APIRouter()
security = HTTPBearer()

@router.post("/register", response_model=AuthResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    try:
        user_service = UserService(db)
        
        # Check if user already exists
        if user_service.get_by_username(user_data.username):
            return AuthResponse(
                success=False,
                message="Username already registered",
                data=None
            )
        
        if user_service.get_by_email(user_data.email):
            return AuthResponse(
                success=False,
                message="Email already registered",
                data=None
            )
        
        # Create user
        user = user_service.create_user(user_data)
        
        # Generate tokens
        access_token = create_access_token(subject=user.id)
        refresh_token = create_refresh_token(subject=user.id)
        
        # Get user with roles and permissions
        user_response = user_service.get_user_with_permissions(user.id)
        
        return AuthResponse(
            success=True,
            message="User registered successfully",
            data={
                "user": user_response,
                "access_token": access_token,
                "refresh_token": refresh_token,
                "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
            }
        )
        
    except Exception as e:
        return AuthResponse(
            success=False,
            message=f"Registration failed: {str(e)}",
            data=None
        )

@router.post("/login", response_model=AuthResponse)
async def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """Authenticate user and return tokens"""
    try:
        user_service = UserService(db)
        
        # Get user by username or email
        user = user_service.authenticate_user(login_data.username, login_data.password)
        if not user:
            return AuthResponse(
                success=False,
                message="Incorrect username or password",
                data=None
            )
        
        # Update last login
        user_service.update_last_login(user.id)
        
        # Generate tokens
        access_token = create_access_token(subject=user.id)
        refresh_token = create_refresh_token(subject=user.id)
        
        # Get user with roles and permissions
        user_response = user_service.get_user_with_permissions(user.id)
        
        return AuthResponse(
            success=True,
            message="Login successful",
            data={
                "user": user_response,
                "access_token": access_token,
                "refresh_token": refresh_token,
                "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
            }
        )
        
    except Exception as e:
        return AuthResponse(
            success=False,
            message=f"Login failed: {str(e)}",
            data=None
        )

@router.post("/logout", response_model=StandardResponse)
async def logout():
    """Logout user (client should delete tokens)"""
    return StandardResponse(
        success=True,
        message="Logged out successfully",
        data=None
    )