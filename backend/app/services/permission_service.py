# app/services/permission_service.py
from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.user import Permission
from app.schemas.permission import PermissionCreate, PermissionUpdate

class PermissionService:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self, include_inactive: bool = False) -> List[Permission]:
        """Get all permissions"""
        query = self.db.query(Permission)
        if not include_inactive:
            query = query.filter(Permission.is_active == True)
        return query.all()

    def get_by_id(self, permission_id: int) -> Optional[Permission]:
        """Get permission by ID"""
        return self.db.query(Permission).filter(Permission.id == permission_id).first()

    def get_by_name(self, name: str) -> Optional[Permission]:
        """Get permission by name"""
        return self.db.query(Permission).filter(Permission.name == name).first()

    def create_permission(self, permission_data: PermissionCreate) -> Permission:
        """Create a new permission"""
        # Check if permission with same name exists
        existing_permission = self.get_by_name(permission_data.name)
        if existing_permission:
            raise ValueError(f"Permission with name '{permission_data.name}' already exists")

        # Create permission
        db_permission = Permission(
            name=permission_data.name,
            display_name=permission_data.display_name,
            description=permission_data.description,
            resource=permission_data.resource,
            action=permission_data.action,
            is_active=permission_data.is_active
        )

        self.db.add(db_permission)
        self.db.commit()
        self.db.refresh(db_permission)

        return db_permission

    def update_permission(self, permission_id: int, permission_data: PermissionUpdate) -> Optional[Permission]:
        """Update an existing permission"""
        db_permission = self.get_by_id(permission_id)
        if not db_permission:
            return None

        # Update fields
        update_dict = permission_data.model_dump(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(db_permission, field, value)

        self.db.commit()
        self.db.refresh(db_permission)

        return db_permission

    def get_permissions_by_resource(self, resource: str) -> List[Permission]:
        """Get all permissions for a specific resource"""
        return self.db.query(Permission).filter(
            Permission.resource == resource,
            Permission.is_active == True
        ).all()
