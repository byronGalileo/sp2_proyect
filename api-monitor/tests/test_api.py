#!/usr/bin/env python3
"""
API Test Script

Test the Service Monitor API endpoints
"""

import os
import sys
import requests
import json
from datetime import datetime

# Setup Python path
project_root = os.path.dirname(os.path.abspath(__file__))
venv_path = os.path.join(project_root, "venv")
venv_site_packages = os.path.join(venv_path, "lib", f"python{sys.version_info.major}.{sys.version_info.minor}", "site-packages")

if os.path.exists(venv_site_packages):
    sys.path.insert(0, venv_site_packages)
sys.path.insert(0, project_root)

def test_endpoint(name, url, method="GET", data=None):
    """Test an API endpoint"""
    print(f"\n🧪 Testing {name}: {method} {url}")
    try:
        if method == "GET":
            response = requests.get(url, timeout=10)
        elif method == "POST":
            response = requests.post(url, json=data, timeout=10)

        print(f"   Status: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Success")

            # Print relevant data
            if isinstance(result, dict):
                if 'total' in result:
                    print(f"   📊 Total: {result['total']}")
                if 'logs' in result and isinstance(result['logs'], list):
                    print(f"   📝 Logs: {len(result['logs'])} entries")
                    if result['logs']:
                        latest = result['logs'][0]
                        print(f"   🕐 Latest: {latest.get('timestamp', 'N/A')}")
                elif 'services' in result and isinstance(result['services'], list):
                    print(f"   🔧 Services: {len(result['services'])}")
                elif 'message' in result:
                    print(f"   💬 Message: {result['message']}")

            return result
        else:
            print(f"   ❌ Error: {response.status_code}")
            try:
                error = response.json()
                print(f"   💬 Detail: {error.get('detail', 'No details')}")
            except:
                print(f"   💬 Response: {response.text[:100]}")

            return None

    except requests.exceptions.ConnectionError:
        print(f"   ❌ Connection failed - API not running on {url}")
        return None
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None

def main():
    # API base URL
    base_url = "http://127.0.0.1:8001"

    print("🎯 Service Monitor API Test Suite")
    print("=" * 50)
    print(f"🌐 API Base URL: {base_url}")

    # Test endpoints
    tests = [
        ("Root Endpoint", f"{base_url}/"),
        ("Health Check", f"{base_url}/health"),
        ("General Statistics", f"{base_url}/stats"),
        ("Services Summary", f"{base_url}/services"),
        ("All Logs", f"{base_url}/logs?limit=5"),
        ("dbus.service Logs", f"{base_url}/logs?service_name=dbus.service&limit=3"),
        ("Unsent Logs", f"{base_url}/logs/unsent?limit=10"),
    ]

    results = {}

    # Run tests
    for name, url in tests:
        results[name] = test_endpoint(name, url)

    # Test mark as sent endpoint if we have unsent logs
    unsent_logs = results.get("Unsent Logs")
    if unsent_logs and unsent_logs.get('logs'):
        print(f"\n🔄 Testing Mark as Sent endpoint...")
        log_ids = [log['id'] for log in unsent_logs['logs'][:2]]  # Take first 2 logs

        mark_sent_result = test_endpoint(
            "Mark Logs as Sent",
            f"{base_url}/logs/mark-sent",
            method="POST",
            data={"log_ids": log_ids}
        )

        if mark_sent_result:
            # Test unsent logs again to verify
            test_endpoint("Unsent Logs (After Marking)", f"{base_url}/logs/unsent?limit=10")

    print(f"\n✅ API Test Suite Completed")
    print(f"🌐 Interactive API Documentation: {base_url}/docs")
    print(f"📚 ReDoc Documentation: {base_url}/redoc")

if __name__ == "__main__":
    main()