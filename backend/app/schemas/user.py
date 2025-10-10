# app/schemas/user.py
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    username: str = Field(..., max_length=50)
    email: str = Field(..., max_length=100)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    phone: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=500)

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)

class UserUpdate(BaseModel):
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    phone: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=500)

class UserAdminUpdate(BaseModel):
    """Schema for admin to update user data"""
    username: Optional[str] = Field(None, max_length=50)
    email: Optional[EmailStr] = Field(None, max_length=100)
    first_name: Optional[str] = Field(None, max_length=50)
    last_name: Optional[str] = Field(None, max_length=50)
    phone: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=500)
    is_active: Optional[bool] = None
    email_verified: Optional[bool] = None
    phone_verified: Optional[bool] = None

class UserResponse(UserBase):
    id: int
    is_active: bool
    email_verified: bool
    phone_verified: bool
    last_login_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    roles: List[str]
    permissions: List[str]

    class Config:
        from_attributes = True

class UserListResponse(BaseModel):
    """Response for listing users"""
    id: int
    username: str
    email: str
    first_name: Optional[str]
    last_name: Optional[str]
    is_active: bool
    email_verified: bool
    last_login_at: Optional[datetime]
    created_at: datetime
    roles: List[str]

    class Config:
        from_attributes = True

class UsersListResponse(BaseModel):
    """Paginated response for users"""
    users: List[UserListResponse]
    total: int
    skip: int
    limit: int

class UserRoleAssignment(BaseModel):
    """Schema to assign roles to a user"""
    role_ids: List[int] = Field(..., min_items=1)

class UserPasswordReset(BaseModel):
    """Schema for admin to reset user password"""
    new_password: str = Field(..., min_length=6)