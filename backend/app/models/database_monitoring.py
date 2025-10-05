# app/models/database_monitoring.py
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey, JSON
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from enum import Enum

class DatabaseType(Enum):
    """Supported database types"""
    MYSQL = "mysql"
    POSTGRESQL = "postgresql"
    SQLSERVER = "sqlserver"
    MONGODB = "mongodb"

class ConnectionStatus(Enum):
    """Connection status enumeration"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    TESTING = "testing"
    FAILED = "failed"

class DatabaseConnection(Base):
    """Database connection model"""
    __tablename__ = "database_connections"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    db_type = Column(String(20), nullable=False)  # mysql, postgresql, sqlserver, mongodb
    hostname = Column(String(255), nullable=False)
    port = Column(Integer, nullable=False)
    database_name = Column(String(100), nullable=False)
    username = Column(String(100), nullable=False)
    password_hash = Column(String(255), nullable=False)  # Encrypted password
    connection_string = Column(Text)  # Optional custom connection string
    ssl_enabled = Column(Boolean, default=False)
    ssl_ca = Column(Text)  # SSL certificate
    timeout_seconds = Column(Integer, default=30)
    max_connections = Column(Integer, default=10)
    is_active = Column(Boolean, default=True)
    status = Column(String(20), default="inactive")  # active, inactive, testing, failed
    last_tested_at = Column(DateTime)
    last_successful_connection = Column(DateTime)
    created_by = Column(BIGINT(unsigned=True).with_variant(Integer, "sqlite"), ForeignKey("users.id"))
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    # Relationships
    creator = relationship("User", back_populates="database_connections")
    monitoring_results = relationship("MonitoringResult", back_populates="connection")

class MonitoringResult(Base):
    """Monitoring result model"""
    __tablename__ = "monitoring_results"

    id = Column(Integer, primary_key=True, index=True)
    connection_id = Column(Integer, ForeignKey("database_connections.id"), nullable=False)
    executed_at = Column(DateTime, server_default=func.now())
    status = Column(String(20), nullable=False)  # success, failed, warning
    response_time_ms = Column(Integer)
    error_message = Column(Text)
    result_data = Column(JSON)  # Store monitoring results as JSON
    log_entries_count = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())

    # Relationships
    connection = relationship("DatabaseConnection", back_populates="monitoring_results")

# Add relationship to User model
from app.models.user import User
User.database_connections = relationship("DatabaseConnection", back_populates="creator")