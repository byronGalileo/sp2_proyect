# app/schemas/role.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class PermissionBase(BaseModel):
    id: int
    name: str
    display_name: str

    class Config:
        from_attributes = True

class RoleBase(BaseModel):
    name: str = Field(..., max_length=50)
    display_name: str = Field(..., max_length=100)
    description: Optional[str] = None

class RoleCreate(RoleBase):
    is_active: bool = True
    permission_ids: Optional[List[int]] = []

class RoleUpdate(BaseModel):
    display_name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    is_active: Optional[bool] = None
    permission_ids: Optional[List[int]] = None

class RoleResponse(RoleBase):
    id: int
    is_system_role: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime
    permissions: List[PermissionBase] = []

    class Config:
        from_attributes = True
