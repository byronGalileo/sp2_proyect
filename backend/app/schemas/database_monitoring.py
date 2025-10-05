# app/schemas/database_monitoring.py
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum

class DatabaseType(str, Enum):
    MYSQL = "mysql"
    POSTGRESQL = "postgresql"
    SQLSERVER = "sqlserver"
    MONGODB = "mongodb"

class ConnectionStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    TESTING = "testing"
    FAILED = "failed"

class DatabaseConnectionBase(BaseModel):
    name: str = Field(..., max_length=100)
    description: Optional[str] = None
    db_type: DatabaseType
    hostname: str = Field(..., max_length=255)
    port: int = Field(..., gt=0, le=65535)
    database_name: str = Field(..., max_length=100)
    username: str = Field(..., max_length=100)
    password: str = Field(..., min_length=1)  # Plain password for input
    connection_string: Optional[str] = None
    ssl_enabled: bool = False
    ssl_ca: Optional[str] = None
    timeout_seconds: int = Field(default=30, gt=0)
    max_connections: int = Field(default=10, gt=0)
    is_active: bool = True

class DatabaseConnectionCreate(DatabaseConnectionBase):
    pass

class DatabaseConnectionUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    description: Optional[str] = None
    hostname: Optional[str] = Field(None, max_length=255)
    port: Optional[int] = Field(None, gt=0, le=65535)
    database_name: Optional[str] = Field(None, max_length=100)
    username: Optional[str] = Field(None, max_length=100)
    password: Optional[str] = Field(None, min_length=1)
    connection_string: Optional[str] = None
    ssl_enabled: Optional[bool] = None
    ssl_ca: Optional[str] = None
    timeout_seconds: Optional[int] = Field(None, gt=0)
    max_connections: Optional[int] = Field(None, gt=0)
    is_active: Optional[bool] = None

class DatabaseConnectionResponse(DatabaseConnectionBase):
    id: int
    status: ConnectionStatus
    last_tested_at: Optional[datetime]
    last_successful_connection: Optional[datetime]
    created_by: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class DatabaseConnectionList(BaseModel):
    connections: List[DatabaseConnectionResponse]
    total: int

class TestConnectionRequest(BaseModel):
    connection_id: int

class TestConnectionResponse(BaseModel):
    success: bool
    message: str
    response_time_ms: Optional[int] = None
    error_details: Optional[str] = None

class MonitoringResultBase(BaseModel):
    connection_id: int
    status: str
    response_time_ms: Optional[int]
    error_message: Optional[str]
    result_data: Optional[Dict[str, Any]]
    log_entries_count: int = 0

class MonitoringResultResponse(MonitoringResultBase):
    id: int
    executed_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class ExecuteMonitoringRequest(BaseModel):
    connection_id: int
    async_execution: bool = False

class ExecuteMonitoringResponse(BaseModel):
    success: bool
    message: str
    result: Optional[MonitoringResultResponse] = None
    task_id: Optional[str] = None  # For async execution

class MonitoringResultsList(BaseModel):
    results: List[MonitoringResultResponse]
    total: int
    connection_id: int