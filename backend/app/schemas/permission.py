# app/schemas/permission.py
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class PermissionBase(BaseModel):
    name: str = Field(..., max_length=100)
    display_name: str = Field(..., max_length=100)
    description: Optional[str] = None
    resource: Optional[str] = Field(None, max_length=50)
    action: Optional[str] = Field(None, max_length=50)

class PermissionCreate(PermissionBase):
    is_active: bool = True

class PermissionUpdate(BaseModel):
    display_name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    resource: Optional[str] = Field(None, max_length=50)
    action: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None

class PermissionResponse(PermissionBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
