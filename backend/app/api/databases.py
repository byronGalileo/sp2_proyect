# app/api/databases.py
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database import get_db
from app.services.database_service import DatabaseService
from app.schemas.database_monitoring import (
    DatabaseConnectionCreate, DatabaseConnectionUpdate, DatabaseConnectionResponse,
    DatabaseConnectionList, TestConnectionResponse, ExecuteMonitoringResponse,
    MonitoringResultsList
)
from app.core.authentication import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=DatabaseConnectionList)
async def list_databases(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """List all database connections for the current user"""
    database_service = DatabaseService(db)
    connections = database_service.get_user_connections(current_user.id, skip, limit)

    return DatabaseConnectionList(
        connections=connections,
        total=len(connections)  # Note: This is approximate, could be improved with count query
    )

@router.post("/", response_model=DatabaseConnectionResponse)
async def create_database(
    connection_data: DatabaseConnectionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new database connection"""
    database_service = DatabaseService(db)
    connection = database_service.create_connection(connection_data, current_user.id)
    return connection

@router.get("/{connection_id}", response_model=DatabaseConnectionResponse)
async def get_database(
    connection_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a specific database connection"""
    database_service = DatabaseService(db)
    connection = database_service.get_connection(connection_id, current_user.id)

    if not connection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Database connection not found"
        )

    return connection

@router.put("/{connection_id}", response_model=DatabaseConnectionResponse)
async def update_database(
    connection_id: int,
    update_data: DatabaseConnectionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update a database connection"""
    database_service = DatabaseService(db)
    connection = database_service.update_connection(connection_id, update_data, current_user.id)

    if not connection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Database connection not found"
        )

    return connection

@router.delete("/{connection_id}")
async def delete_database(
    connection_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete a database connection"""
    database_service = DatabaseService(db)
    success = database_service.delete_connection(connection_id, current_user.id)

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Database connection not found"
        )

    return {"message": "Database connection deleted successfully"}

@router.post("/{connection_id}/test", response_model=TestConnectionResponse)
async def test_database_connection(
    connection_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Test database connection"""
    database_service = DatabaseService(db)
    result = database_service.test_connection(connection_id, current_user.id)
    return result