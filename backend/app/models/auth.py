# app/schemas/auth.py
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    email_verified: bool
    last_login_at: Optional[datetime] = None
    created_at: datetime
    roles: List[str] = []
    permissions: List[str] = []
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

class AuthResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None
