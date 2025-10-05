# app/config.py
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "mysql+pymysql://user:password@localhost:3306/monitoring_db"
    
    # Security
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",  # Flutter web dev
        "http://localhost:8080",  # Flutter web dev
        "http://localhost:50608", # Flutter app dev
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:50608", # Flutter app dev
    ]
    
    # Redis (for Celery)
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # Email (optional, for future features)
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    
    class Config:
        env_file = ".env"

settings = Settings()