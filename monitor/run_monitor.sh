#!/bin/bash
# Service Monitor v2.0 Wrapper Script
# This script automatically activates the virtual environment and runs the monitor

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VENV_PATH="$PROJECT_ROOT/venv"

# Check if virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Virtual environment not found at: $VENV_PATH"
    echo "💡 Run this from the project root to create it:"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements_mongodb.txt"
    exit 1
fi

# Check if virtual environment has the required packages
if [ ! -f "$VENV_PATH/lib/python3.12/site-packages/pymongo/__init__.py" ]; then
    echo "❌ pymongo not found in virtual environment"
    echo "💡 Install dependencies:"
    echo "   source $VENV_PATH/bin/activate"
    echo "   pip install -r ../requirements_mongodb.txt"
    exit 1
fi

# Activate virtual environment and run monitor
echo "🚀 Starting Service Monitor v2.0..."
echo "📁 Project root: $PROJECT_ROOT"
echo "🐍 Using virtual environment: $VENV_PATH"

# Change to monitor directory
cd "$SCRIPT_DIR"

# Activate virtual environment and run monitor with all passed arguments
source "$VENV_PATH/bin/activate" && python monitor.py "$@"