# app/services/user_service.py
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from datetime import datetime

from app.models.user import User, Role
from app.schemas.auth import UserCreate
from app.core.security import get_password_hash, verify_password

class UserService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_by_username(self, username: str) -> Optional[User]:
        return self.db.query(User).filter(User.username == username).first()
    
    def get_by_email(self, email: str) -> Optional[User]:
        return self.db.query(User).filter(User.email == email).first()
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        return self.db.query(User).filter(User.id == user_id).first()
    
    def create_user(self, user_data: UserCreate) -> User:
        # Create user
        db_user = User(
            username=user_data.username,
            email=user_data.email,
            password_hash=get_password_hash(user_data.password),
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            phone=user_data.phone,
            is_active=True
        )
        
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        
        # Assign default role
        default_role = self.db.query(Role).filter(Role.name == "user").first()
        if default_role:
            db_user.roles.append(default_role)
            self.db.commit()
        
        return db_user
    
    def authenticate_user(self, username: str, password: str) -> Optional[User]:
        # Allow login with username or email
        user = self.db.query(User).filter(
            or_(User.username == username, User.email == username)
        ).first()
        
        if not user or not verify_password(password, user.password_hash):
            return None
        
        if not user.is_active:
            return None
        
        return user
    
    def update_last_login(self, user_id: int):
        user = self.get_by_id(user_id)
        if user:
            user.last_login_at = datetime.utcnow()
            self.db.commit()
    
    def get_user_with_permissions(self, user_id: int) -> dict:
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return None

        roles = [role.name for role in user.roles]
        permissions = []
        for role in user.roles:
            permissions.extend([perm.name for perm in role.permissions])

        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "phone": user.phone,
            "avatar_url": user.avatar_url,
            "is_active": user.is_active,
            "email_verified": user.email_verified,
            "phone_verified": user.phone_verified,
            "last_login_at": user.last_login_at,
            "created_at": user.created_at,
            "updated_at": user.updated_at,
            "roles": roles,
            "permissions": list(set(permissions))  # Remove duplicates
        }

    def get_all_users(self, skip: int = 0, limit: int = 100, is_active: Optional[bool] = None) -> Tuple[List[User], int]:
        """Get all users with pagination and optional filtering"""
        query = self.db.query(User)

        if is_active is not None:
            query = query.filter(User.is_active == is_active)

        total = query.count()
        users = query.offset(skip).limit(limit).all()

        return users, total

    def update_user(self, user_id: int, update_data: dict) -> Optional[User]:
        """Update user data (admin only)"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        for field, value in update_data.items():
            if hasattr(user, field):
                setattr(user, field, value)

        user.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(user)

        return user

    def deactivate_user(self, user_id: int) -> Optional[User]:
        """Deactivate a user (soft delete)"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        user.is_active = False
        user.deleted_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(user)

        return user

    def activate_user(self, user_id: int) -> Optional[User]:
        """Activate a user"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        user.is_active = True
        user.deleted_at = None
        self.db.commit()
        self.db.refresh(user)

        return user

    def assign_roles(self, user_id: int, role_ids: List[int]) -> Optional[User]:
        """Assign roles to a user"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        roles = self.db.query(Role).filter(Role.id.in_(role_ids)).all()
        user.roles = roles
        self.db.commit()
        self.db.refresh(user)

        return user

    def add_role(self, user_id: int, role_id: int) -> Optional[User]:
        """Add a single role to a user"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            return None

        if role not in user.roles:
            user.roles.append(role)
            self.db.commit()
            self.db.refresh(user)

        return user

    def remove_role(self, user_id: int, role_id: int) -> Optional[User]:
        """Remove a role from a user"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        role = self.db.query(Role).filter(Role.id == role_id).first()
        if not role:
            return None

        if role in user.roles:
            user.roles.remove(role)
            self.db.commit()
            self.db.refresh(user)

        return user

    def reset_password(self, user_id: int, new_password: str) -> Optional[User]:
        """Reset user password (admin action)"""
        user = self.get_by_id(user_id)
        if not user:
            return None

        user.password_hash = get_password_hash(new_password)
        user.password_changed_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(user)

        return user
