# app/services/role_permission_service.py
from typing import Optional, List
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_

from app.models.user import RolePermission, Role, Permission
from app.schemas.role_permission import RolePermissionCreate, RolePermissionUpdate

class RolePermissionService:
    def __init__(self, db: Session):
        self.db = db

    def get_all(self) -> List[dict]:
        """Get all role-permission assignments with joined data"""
        role_permissions = self.db.query(RolePermission).options(
            joinedload(RolePermission.role),
            joinedload(RolePermission.permission)
        ).all()

        print(role_permissions)

        return [
            {
                "id": rp.id,
                "role_id": rp.role_id,
                "permission_id": rp.permission_id,
                "created_at": rp.created_at,
                "role_name": rp.role.name,
                "role_display_name": rp.role.display_name,
                "permission_name": rp.permission.name,
                "permission_display_name": rp.permission.display_name
            }
            for rp in role_permissions
        ]

    def get_by_id(self, role_permission_id: int) -> Optional[RolePermission]:
        """Get role-permission assignment by ID"""
        return self.db.query(RolePermission).options(
            joinedload(RolePermission.role),
            joinedload(RolePermission.permission)
        ).filter(RolePermission.id == role_permission_id).first()

    def get_by_role_id(self, role_id: int) -> List[dict]:
        """Get all permissions for a specific role"""
        role_permissions = self.db.query(RolePermission).options(
            joinedload(RolePermission.role),
            joinedload(RolePermission.permission)
        ).filter(RolePermission.role_id == role_id).all()

        return [
            {
                "id": rp.id,
                "role_id": rp.role_id,
                "permission_id": rp.permission_id,
                "created_at": rp.created_at,
                "role_name": rp.role.name,
                "role_display_name": rp.role.display_name,
                "permission_name": rp.permission.name,
                "permission_display_name": rp.permission.display_name
            }
            for rp in role_permissions
        ]

    def get_by_permission_id(self, permission_id: int) -> List[dict]:
        """Get all roles that have a specific permission"""
        role_permissions = self.db.query(RolePermission).options(
            joinedload(RolePermission.role),
            joinedload(RolePermission.permission)
        ).filter(RolePermission.permission_id == permission_id).all()

        return [
            {
                "id": rp.id,
                "role_id": rp.role_id,
                "permission_id": rp.permission_id,
                "created_at": rp.created_at,
                "role_name": rp.role.name,
                "role_display_name": rp.role.display_name,
                "permission_name": rp.permission.name,
                "permission_display_name": rp.permission.display_name
            }
            for rp in role_permissions
        ]

    def create_role_permission(self, role_permission_data: RolePermissionCreate) -> RolePermission:
        """Assign a permission to a role"""
        # Check if role exists
        role = self.db.query(Role).filter(Role.id == role_permission_data.role_id).first()
        if not role:
            raise ValueError(f"Role with ID {role_permission_data.role_id} not found")

        # Check if permission exists
        permission = self.db.query(Permission).filter(Permission.id == role_permission_data.permission_id).first()
        if not permission:
            raise ValueError(f"Permission with ID {role_permission_data.permission_id} not found")

        # Check if assignment already exists
        existing = self.db.query(RolePermission).filter(
            and_(
                RolePermission.role_id == role_permission_data.role_id,
                RolePermission.permission_id == role_permission_data.permission_id
            )
        ).first()

        if existing:
            raise ValueError(f"Permission {permission.name} is already assigned to role {role.name}")

        # Create assignment
        db_role_permission = RolePermission(
            role_id=role_permission_data.role_id,
            permission_id=role_permission_data.permission_id
        )

        self.db.add(db_role_permission)
        self.db.commit()
        self.db.refresh(db_role_permission)

        # Load relationships
        return self.get_by_id(db_role_permission.id)

    def update_role_permission(self, role_permission_id: int, role_permission_data: RolePermissionUpdate) -> Optional[RolePermission]:
        """Update a role-permission assignment"""
        db_role_permission = self.db.query(RolePermission).filter(
            RolePermission.id == role_permission_id
        ).first()

        if not db_role_permission:
            return None

        # Update permission_id if provided
        if role_permission_data.permission_id is not None:
            # Check if new permission exists
            permission = self.db.query(Permission).filter(
                Permission.id == role_permission_data.permission_id
            ).first()
            if not permission:
                raise ValueError(f"Permission with ID {role_permission_data.permission_id} not found")

            # Check if this would create a duplicate
            existing = self.db.query(RolePermission).filter(
                and_(
                    RolePermission.role_id == db_role_permission.role_id,
                    RolePermission.permission_id == role_permission_data.permission_id,
                    RolePermission.id != role_permission_id
                )
            ).first()

            if existing:
                raise ValueError(f"Permission {permission.name} is already assigned to this role")

            db_role_permission.permission_id = role_permission_data.permission_id

        self.db.commit()
        self.db.refresh(db_role_permission)

        # Load relationships
        return self.get_by_id(db_role_permission.id)
