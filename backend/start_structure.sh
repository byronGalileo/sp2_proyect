#!/bin/bash

# Define the base directory name
BASE_DIR="app"

# Remove the existing directory if it exists to start fresh
rm -rf "$BASE_DIR"

# Create the main app directory
mkdir -p "$BASE_DIR"

# Create all necessary subdirectories
mkdir -p "$BASE_DIR"/config
mkdir -p "$BASE_DIR"/database
mkdir -p "$BASE_DIR"/dependencies
mkdir -p "$BASE_DIR"/models
mkdir -p "$BASE_DIR"/schemas
mkdir -p "$BASE_DIR"/api
mkdir -p "$BASE_DIR"/core
mkdir -p "$BASE_DIR"/services
mkdir -p "$BASE_DIR"/tasks
mkdir -p "$BASE_DIR"/utils

# Create the initial files
touch "$BASE_DIR"/main.py
touch "$BASE_DIR"/config.py
touch "$BASE_DIR"/database.py
touch "$BASE_DIR"/dependencies.py

# Create files in the models directory
touch "$BASE_DIR"/models/__init__.py
touch "$BASE_DIR"/models/user.py
touch "$BASE_DIR"/models/auth.py
touch "$BASE_DIR"/models/database_monitoring.py
touch "$BASE_DIR"/models/system.py

# Create files in the schemas directory
touch "$BASE_DIR"/schemas/__init__.py
touch "$BASE_DIR"/schemas/user.py
touch "$BASE_DIR"/schemas/auth.py
touch "$BASE_DIR"/schemas/database_monitoring.py
touch "$BASE_DIR"/schemas/common.py

# Create files in the api directory
touch "$BASE_DIR"/api/__init__.py
touch "$BASE_DIR"/api/deps.py
touch "$BASE_DIR"/api/auth.py
touch "$BASE_DIR"/api/users.py
touch "$BASE_DIR"/api/databases.py
touch "$BASE_DIR"/api/monitoring.py

# Create files in the core directory
touch "$BASE_DIR"/core/__init__.py
touch "$BASE_DIR"/core/authentication.py
touch "$BASE_DIR"/core/security.py
touch "$BASE_DIR"/core/permissions.py

# Create files in the services directory
touch "$BASE_DIR"/services/__init__.py
touch "$BASE_DIR"/services/user_service.py
touch "$BASE_DIR"/services/database_service.py
touch "$BASE_DIR"/services/monitoring_service.py

# Create files in the tasks directory
touch "$BASE_DIR"/tasks/__init__.py
touch "$BASE_DIR"/tasks/celery_app.py
touch "$BASE_DIR"/tasks/monitoring_tasks.py

# Create files in the utils directory
touch "$BASE_DIR"/utils/__init__.py
touch "$BASE_DIR"/utils/encryption.py
touch "$BASE_DIR"/utils/helpers.py

echo "File structure created successfully."