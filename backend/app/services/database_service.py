# app/services/database_service.py
import logging
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from datetime import datetime
import pymysql
import psycopg2
import pyodbc
import pymongo
from cryptography.fernet import Fernet

from app.models.database_monitoring import DatabaseConnection, MonitoringResult, DatabaseType, ConnectionStatus
from app.schemas.database_monitoring import (
    DatabaseConnectionCreate, DatabaseConnectionUpdate,
    TestConnectionResponse, ExecuteMonitoringResponse
)
from app.config import settings
from app.core.logger_manager import LoggerManager

logger = logging.getLogger(__name__)

class DatabaseService:
    """Service for managing database connections and monitoring"""

    def __init__(self, db: Session):
        self.db = db
        print(settings.SECRET_ENCODE)
        self.cipher = Fernet(settings.SECRET_ENCODE.encode())
        # Initialize logger manager for MongoDB logging
        self.logger_manager = LoggerManager(
            log_path="logs/database_service.log",
            mongodb_config={
                "enabled": True,
                "host": "localhost",  # Should be configurable
                "port": 27017,
                "database": "monitoring_logs",
                "username": "",  # Should be from config
                "password": ""   # Should be from config
            }
        )

    def _encrypt_password(self, password: str) -> str:
        """Encrypt password for storage"""
        return self.cipher.encrypt(password.encode()).decode()

    def _decrypt_password(self, encrypted_password: str) -> str:
        """Decrypt password for use"""
        return self.cipher.decrypt(encrypted_password.encode()).decode()

    def create_connection(self, connection_data: DatabaseConnectionCreate, user_id: int) -> DatabaseConnection:
        """Create a new database connection"""
        db_connection = DatabaseConnection(
            name=connection_data.name,
            description=connection_data.description,
            db_type=connection_data.db_type.value,
            hostname=connection_data.hostname,
            port=connection_data.port,
            database_name=connection_data.database_name,
            username=connection_data.username,
            password_hash=self._encrypt_password(connection_data.password),
            connection_string=connection_data.connection_string,
            ssl_enabled=connection_data.ssl_enabled,
            ssl_ca=connection_data.ssl_ca,
            timeout_seconds=connection_data.timeout_seconds,
            max_connections=connection_data.max_connections,
            is_active=connection_data.is_active,
            status=ConnectionStatus.INACTIVE.value,
            created_by=user_id
        )

        self.db.add(db_connection)
        self.db.commit()
        self.db.refresh(db_connection)
        return db_connection

    def get_connection(self, connection_id: int, user_id: int) -> Optional[DatabaseConnection]:
        """Get a database connection by ID"""
        return self.db.query(DatabaseConnection).filter(
            DatabaseConnection.id == connection_id,
            DatabaseConnection.created_by == user_id
        ).first()

    def get_user_connections(self, user_id: int, skip: int = 0, limit: int = 100) -> List[DatabaseConnection]:
        """Get all connections for a user"""
        return self.db.query(DatabaseConnection).filter(
            DatabaseConnection.created_by == user_id
        ).offset(skip).limit(limit).all()

    def update_connection(self, connection_id: int, update_data: DatabaseConnectionUpdate, user_id: int) -> Optional[DatabaseConnection]:
        """Update a database connection"""
        connection = self.get_connection(connection_id, user_id)
        if not connection:
            return None

        update_dict = update_data.model_dump(exclude_unset=True)

        # Encrypt password if provided
        if 'password' in update_dict:
            update_dict['password_hash'] = self._encrypt_password(update_dict.pop('password'))

        for field, value in update_dict.items():
            setattr(connection, field, value)

        connection.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(connection)
        return connection

    def delete_connection(self, connection_id: int, user_id: int) -> bool:
        """Delete a database connection"""
        connection = self.get_connection(connection_id, user_id)
        if not connection:
            return False

        self.db.delete(connection)
        self.db.commit()
        return True

    def test_connection(self, connection_id: int, user_id: int) -> TestConnectionResponse:
        """Test database connection"""
        connection = self.get_connection(connection_id, user_id)
        if not connection:
            return TestConnectionResponse(
                success=False,
                message="Connection not found",
                error_details="Database connection does not exist or access denied"
            )

        connection.status = ConnectionStatus.TESTING.value
        self.db.commit()

        start_time = datetime.utcnow()

        try:
            # Test the connection based on database type
            success = self._test_db_connection(connection)
            response_time = int((datetime.utcnow() - start_time).total_seconds() * 1000)

            if success:
                connection.status = ConnectionStatus.ACTIVE.value
                connection.last_successful_connection = datetime.utcnow()
                message = f"Connection to {connection.name} successful"

                # Log successful connection test
                self.logger_manager.log_service_status(
                    target_name=connection.name,
                    service_name=f"db_{connection.db_type}",
                    status="active",
                    is_active=True,
                    host=connection.hostname,
                    service_type="database",
                    metadata={
                        'db_type': connection.db_type,
                        'response_time_ms': response_time,
                        'user_id': user_id
                    }
                )
            else:
                connection.status = ConnectionStatus.FAILED.value
                message = f"Connection to {connection.name} failed"

                # Log failed connection test
                self.logger_manager.log_service_status(
                    target_name=connection.name,
                    service_name=f"db_{connection.db_type}",
                    status="failed",
                    is_active=False,
                    host=connection.hostname,
                    service_type="database",
                    metadata={
                        'db_type': connection.db_type,
                        'error': error_details,
                        'user_id': user_id
                    },
                    error=error_details
                )

            connection.last_tested_at = datetime.utcnow()
            self.db.commit()

            return TestConnectionResponse(
                success=success,
                message=message,
                response_time_ms=response_time,
                error_details=error_details
            )

        except Exception as e:
            connection.status = ConnectionStatus.FAILED.value
            connection.last_tested_at = datetime.utcnow()
            self.db.commit()

            return TestConnectionResponse(
                success=False,
                message=f"Connection test failed: {str(e)}",
                error_details=str(e)
            )

    def _test_db_connection(self, connection: DatabaseConnection) -> bool:
        """Test actual database connection"""
        try:
            password = self._decrypt_password(connection.password_hash)

            if connection.db_type == DatabaseType.MYSQL.value:
                conn = pymysql.connect(
                    host=connection.hostname,
                    port=connection.port,
                    user=connection.username,
                    password=password,
                    database=connection.database_name,
                    connect_timeout=connection.timeout_seconds,
                    ssl={'ca': connection.ssl_ca} if connection.ssl_enabled and connection.ssl_ca else None
                )
                conn.close()
                return True

            elif connection.db_type == DatabaseType.POSTGRESQL.value:
                conn = psycopg2.connect(
                    host=connection.hostname,
                    port=connection.port,
                    user=connection.username,
                    password=password,
                    database=connection.database_name,
                    connect_timeout=connection.timeout_seconds,
                    sslmode='require' if connection.ssl_enabled else 'disable'
                )
                conn.close()
                return True

            elif connection.db_type == DatabaseType.SQLSERVER.value:
                conn_str = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={connection.hostname},{connection.port};DATABASE={connection.database_name};UID={connection.username};PWD={password}"
                conn = pyodbc.connect(conn_str, timeout=connection.timeout_seconds)
                conn.close()
                return True

            elif connection.db_type == DatabaseType.MONGODB.value:
                client = pymongo.MongoClient(
                    host=connection.hostname,
                    port=connection.port,
                    username=connection.username,
                    password=password,
                    authSource=connection.database_name,
                    serverSelectionTimeoutMS=connection.timeout_seconds * 1000,
                    ssl=connection.ssl_enabled
                )
                # Test connection
                client.server_info()
                client.close()
                return True

            else:
                raise ValueError(f"Unsupported database type: {connection.db_type}")

        except Exception as e:
            logger.error(f"Database connection test failed: {e}")
            return False

    def execute_monitoring(self, connection_id: int, user_id: int) -> ExecuteMonitoringResponse:
        """Execute monitoring for a database connection"""
        connection = self.get_connection(connection_id, user_id)
        if not connection:
            return ExecuteMonitoringResponse(
                success=False,
                message="Connection not found"
            )

        try:
            # Test the connection first
            test_result = self.test_connection(connection_id, user_id)
            if not test_result.success:
                return ExecuteMonitoringResponse(
                    success=False,
                    message=f"Connection test failed: {test_result.message}"
                )

            # Create monitoring result
            monitoring_result = MonitoringResult(
                connection_id=connection_id,
                status="success",
                response_time_ms=test_result.response_time_ms,
                result_data={
                    "connection_status": "active",
                    "database_type": connection.db_type,
                    "hostname": connection.hostname,
                    "database_name": connection.database_name
                }
            )

            self.db.add(monitoring_result)
            self.db.commit()
            self.db.refresh(monitoring_result)

            return ExecuteMonitoringResponse(
                success=True,
                message="Monitoring executed successfully",
                result=monitoring_result
            )

        except Exception as e:
            # Create failed monitoring result
            monitoring_result = MonitoringResult(
                connection_id=connection_id,
                status="failed",
                error_message=str(e)
            )

            self.db.add(monitoring_result)
            self.db.commit()
            self.db.refresh(monitoring_result)

            return ExecuteMonitoringResponse(
                success=False,
                message=f"Monitoring failed: {str(e)}",
                result=monitoring_result
            )

    def get_monitoring_results(self, connection_id: int, user_id: int, skip: int = 0, limit: int = 50) -> List[MonitoringResult]:
        """Get monitoring results for a connection"""
        # Verify user owns the connection
        connection = self.get_connection(connection_id, user_id)
        if not connection:
            return []

        return self.db.query(MonitoringResult).filter(
            MonitoringResult.connection_id == connection_id
        ).order_by(MonitoringResult.executed_at.desc()).offset(skip).limit(limit).all()