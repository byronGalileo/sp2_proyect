# app/schemas/role_permission.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class RoleInfo(BaseModel):
    id: int
    name: str
    display_name: str

    class Config:
        from_attributes = True

class PermissionInfo(BaseModel):
    id: int
    name: str
    display_name: str

    class Config:
        from_attributes = True

class RolePermissionBase(BaseModel):
    role_id: int
    permission_id: int

class RolePermissionCreate(RolePermissionBase):
    pass

class RolePermissionUpdate(BaseModel):
    permission_id: Optional[int] = None

class RolePermissionResponse(RolePermissionBase):
    id: int
    created_at: datetime
    role: RoleInfo
    permission: PermissionInfo

    class Config:
        from_attributes = True

class RolePermissionListResponse(BaseModel):
    id: int
    role_id: int
    permission_id: int
    created_at: datetime
    role_name: str
    role_display_name: str
    permission_name: str
    permission_display_name: str

    class Config:
        from_attributes = True
