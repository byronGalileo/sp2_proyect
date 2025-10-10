# app/main.py
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from contextlib import asynccontextmanager
import uvicorn

from app.config import settings
from app.database import engine, Base
from app.api import auth, users, databases, monitoring, roles, permissions, role_permissions

# Create tables on startup
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    Base.metadata.create_all(bind=engine)
    yield
    # Shutdown
    pass

# Initialize FastAPI app
app = FastAPI(
    title="System Monitor API",
    description="API for Systems Monitoring",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])
app.include_router(roles.router, prefix="/api/v1/roles", tags=["Roles"])
app.include_router(permissions.router, prefix="/api/v1/permissions", tags=["Permissions"])
app.include_router(role_permissions.router, prefix="/api/v1/role-permissions", tags=["Role Permissions"])
app.include_router(databases.router, prefix="/api/v1/databases", tags=["Databases"])
app.include_router(monitoring.router, prefix="/api/v1/monitoring", tags=["Monitoring"])

@app.get("/")
async def root():
    return {"message": "System Monitor API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )