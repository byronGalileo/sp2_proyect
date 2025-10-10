# app/services/role_service.py
from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.models.user import Role, Permission
from app.schemas.role import RoleCreate, RoleUpdate

class RoleService:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self, include_inactive: bool = False) -> List[Role]:
        """Get all roles"""
        query = self.db.query(Role)
        if not include_inactive:
            query = query.filter(Role.is_active == True)
        return query.all()

    def get_by_id(self, role_id: int) -> Optional[Role]:
        """Get role by ID"""
        return self.db.query(Role).filter(Role.id == role_id).first()

    def get_by_name(self, name: str) -> Optional[Role]:
        """Get role by name"""
        return self.db.query(Role).filter(Role.name == name).first()

    def create_role(self, role_data: RoleCreate) -> Role:
        """Create a new role"""
        # Check if role with same name exists
        existing_role = self.get_by_name(role_data.name)
        if existing_role:
            raise ValueError(f"Role with name '{role_data.name}' already exists")

        # Create role
        db_role = Role(
            name=role_data.name,
            display_name=role_data.display_name,
            description=role_data.description,
            is_active=role_data.is_active,
            is_system_role=False
        )

        # Add permissions if provided
        if role_data.permission_ids:
            permissions = self.db.query(Permission).filter(
                Permission.id.in_(role_data.permission_ids)
            ).all()
            db_role.permissions = permissions

        self.db.add(db_role)
        self.db.commit()
        self.db.refresh(db_role)

        return db_role

    def update_role(self, role_id: int, role_data: RoleUpdate) -> Optional[Role]:
        """Update an existing role"""
        db_role = self.get_by_id(role_id)
        if not db_role:
            return None

        # Prevent modification of system roles
        if db_role.is_system_role:
            raise ValueError("System roles cannot be modified")

        # Update fields
        update_dict = role_data.model_dump(exclude_unset=True, exclude={"permission_ids"})
        for field, value in update_dict.items():
            setattr(db_role, field, value)

        # Update permissions if provided
        if role_data.permission_ids is not None:
            permissions = self.db.query(Permission).filter(
                Permission.id.in_(role_data.permission_ids)
            ).all()
            db_role.permissions = permissions

        self.db.commit()
        self.db.refresh(db_role)

        return db_role

    def delete_role(self, role_id: int) -> bool:
        """Delete a role (soft delete by setting is_active to False)"""
        db_role = self.get_by_id(role_id)
        if not db_role:
            return False

        # Prevent deletion of system roles
        if db_role.is_system_role:
            raise ValueError("System roles cannot be deleted")

        # Check if role is assigned to any users
        if db_role.users:
            raise ValueError("Cannot delete role that is assigned to users")

        db_role.is_active = False
        self.db.commit()

        return True

    def get_role_with_details(self, role_id: int) -> Optional[dict]:
        """Get role with permissions details"""
        role = self.get_by_id(role_id)
        if not role:
            return None

        return {
            "id": role.id,
            "name": role.name,
            "display_name": role.display_name,
            "description": role.description,
            "is_system_role": role.is_system_role,
            "is_active": role.is_active,
            "created_at": role.created_at,
            "updated_at": role.updated_at,
            "permissions": [
                {
                    "id": perm.id,
                    "name": perm.name,
                    "display_name": perm.display_name
                }
                for perm in role.permissions
            ]
        }
