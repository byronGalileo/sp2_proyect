# app/dependencies.py
from app.core.authentication import get_current_user

# Re-export commonly used dependencies
__all__ = ["get_current_user"]