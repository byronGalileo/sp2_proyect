# app/schemas/user.py
from pydantic import BaseModel, Field
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