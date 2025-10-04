#!/bin/bash
# Database Example Wrapper Script
# This script automatically activates the virtual environment and runs the database example

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="$SCRIPT_DIR/venv"

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
    echo "   pip install -r requirements_mongodb.txt"
    exit 1
fi

echo "🚀 Running MongoDB Database Example..."
echo "📁 Project root: $SCRIPT_DIR"
echo "🐍 Using virtual environment: $VENV_PATH"

# Activate virtual environment and run database example
source "$VENV_PATH/bin/activate" && python database/example_usage.py