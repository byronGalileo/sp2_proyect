#!/usr/bin/env python3
"""
Service Monitor v2.0 Python Wrapper
This wrapper automatically sets up the Python path and virtual environment
"""

import os
import sys
import subprocess
from pathlib import Path

def find_project_root():
    """Find the project root directory"""
    current = Path(__file__).parent
    # Look for venv directory or requirements file
    for parent in [current] + list(current.parents):
        if (parent / "venv").exists() or (parent / "requirements_mongodb.txt").exists():
            return parent
    return current.parent

def setup_python_path():
    """Setup Python path for imports"""
    project_root = find_project_root()

    # Add project root to Python path
    if str(project_root) not in sys.path:
        sys.path.insert(0, str(project_root))

    # Check for virtual environment
    venv_path = project_root / "venv"
    if venv_path.exists():
        # Add virtual environment to path
        venv_site_packages = venv_path / "lib" / f"python{sys.version_info.major}.{sys.version_info.minor}" / "site-packages"
        if venv_site_packages.exists() and str(venv_site_packages) not in sys.path:
            sys.path.insert(0, str(venv_site_packages))

    return project_root, venv_path

def check_dependencies():
    """Check if required dependencies are available"""
    try:
        import pymongo
        return True
    except ImportError:
        return False

def main():
    """Main wrapper function"""
    print("🚀 Service Monitor v2.0 - Python Wrapper")

    # Setup paths
    project_root, venv_path = setup_python_path()
    print(f"📁 Project root: {project_root}")

    # Check dependencies
    if not check_dependencies():
        print("❌ Required dependencies not found!")
        print("💡 Please install dependencies:")
        print(f"   cd {project_root}")
        print("   source venv/bin/activate")
        print("   pip install -r requirements_mongodb.txt")
        sys.exit(1)

    print("✅ Dependencies found")

    # Change to monitor directory
    monitor_dir = Path(__file__).parent
    os.chdir(monitor_dir)

    # Import and run the actual monitor
    try:
        from core import ConfigLoader, ServiceMonitor, LoggerManager

        # Import the main function from the original monitor
        sys.path.insert(0, str(monitor_dir))
        import monitor

        # Run the main function with original arguments
        sys.argv[0] = "monitor.py"  # Fix script name for argument parsing
        sys.exit(monitor.main())

    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Make sure all modules are properly installed and accessible")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error running monitor: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()