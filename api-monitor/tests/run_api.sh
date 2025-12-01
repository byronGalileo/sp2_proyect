#!/bin/bash
# Service Monitor API Wrapper Script
# This script automatically activates the virtual environment and runs the API

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
if [ ! -f "$VENV_PATH/lib/python3.12/site-packages/fastapi/__init__.py" ]; then
    echo "❌ FastAPI not found in virtual environment"
    echo "💡 Install API dependencies:"
    echo "   source $VENV_PATH/bin/activate"
    echo "   pip install -r requirements_mongodb.txt"
    exit 1
fi

echo "🚀 Starting Service Monitor API..."
echo "📁 Project root: $SCRIPT_DIR"
echo "🐍 Using virtual environment: $VENV_PATH"

# Default values
HOST=${1:-"0.0.0.0"}
PORT=${2:-"8000"}

# Change to API directory
cd "$SCRIPT_DIR/api"

echo "🌐 API will be available at: http://$HOST:$PORT"
echo "📚 Documentation: http://$HOST:$PORT/docs"
echo "🔧 Interactive API: http://$HOST:$PORT/redoc"
echo ""

# Activate virtual environment and run API with all passed arguments
source "$VENV_PATH/bin/activate" && python main.py --host "$HOST" --port "$PORT" "${@:3}"