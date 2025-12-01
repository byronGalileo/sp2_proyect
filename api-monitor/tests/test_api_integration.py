#!/usr/bin/env python3
"""
Test script for API integration
Tests the new hosts and services endpoints
"""

import requests
import json
import sys

API_BASE = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("\n[TEST] Health Check")
    try:
        response = requests.get(f"{API_BASE}/health")
        if response.status_code == 200:
            print("✓ Health check passed")
            print(f"  Database connected: {response.json()['database']['connected']}")
            return True
        else:
            print(f"✗ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Health check error: {e}")
        return False


def test_create_host():
    """Test creating a host"""
    print("\n[TEST] Create Host")

    host_data = {
        "host_id": "test_host_001",
        "hostname": "test-server",
        "ip_address": "192.168.1.100",
        "environment": "development",
        "region": "local",
        "ssh_config": {
            "user": "ubuntu",
            "port": 22,
            "use_sudo": True
        },
        "metadata": {
            "os": "Ubuntu 22.04",
            "purpose": "Test Server",
            "tags": ["test", "development"]
        }
    }

    try:
        response = requests.post(f"{API_BASE}/hosts", json=host_data)
        if response.status_code in [200, 201]:
            print("✓ Host created successfully")
            print(f"  Host ID: {response.json()['data']['host_id']}")
            return True
        elif response.status_code == 409:
            print("⚠ Host already exists (expected if running multiple times)")
            return True
        else:
            print(f"✗ Failed to create host: {response.status_code}")
            print(f"  Error: {response.json()}")
            return False
    except Exception as e:
        print(f"✗ Error creating host: {e}")
        return False


def test_get_hosts():
    """Test getting hosts"""
    print("\n[TEST] Get Hosts")

    try:
        response = requests.get(f"{API_BASE}/hosts")
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Retrieved {data['data']['count']} hosts")
            return True
        else:
            print(f"✗ Failed to get hosts: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting hosts: {e}")
        return False


def test_get_specific_host():
    """Test getting a specific host"""
    print("\n[TEST] Get Specific Host")

    try:
        response = requests.get(f"{API_BASE}/hosts/test_host_001")
        if response.status_code == 200:
            host = response.json()['data']
            print(f"✓ Retrieved host: {host['hostname']}")
            print(f"  Environment: {host['environment']}")
            print(f"  Region: {host['region']}")
            return True
        else:
            print(f"✗ Failed to get host: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting host: {e}")
        return False


def test_create_service():
    """Test creating a service"""
    print("\n[TEST] Create Service")

    service_data = {
        "service_id": "test_svc_001",
        "host_id": "test_host_001",
        "service_name": "nginx",
        "service_type": "nginx",
        "display_name": "Test Nginx Service",
        "description": "Test nginx instance",
        "monitoring": {
            "enabled": True,
            "interval_sec": 60
        },
        "recovery": {
            "recover_on_down": True,
            "recover_action": "restart"
        },
        "tags": ["test", "web"]
    }

    try:
        response = requests.post(f"{API_BASE}/services", json=service_data)
        if response.status_code in [200, 201]:
            print("✓ Service created successfully")
            print(f"  Service ID: {response.json()['data']['service_id']}")
            return True
        elif response.status_code == 409:
            print("⚠ Service already exists (expected if running multiple times)")
            return True
        else:
            print(f"✗ Failed to create service: {response.status_code}")
            print(f"  Error: {response.json()}")
            return False
    except Exception as e:
        print(f"✗ Error creating service: {e}")
        return False


def test_get_services():
    """Test getting services"""
    print("\n[TEST] Get Services")

    try:
        response = requests.get(f"{API_BASE}/services")
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Retrieved {data['data']['count']} services")
            return True
        else:
            print(f"✗ Failed to get services: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting services: {e}")
        return False


def test_get_services_by_host():
    """Test getting services by host"""
    print("\n[TEST] Get Services by Host")

    try:
        response = requests.get(f"{API_BASE}/services?host_id=test_host_001")
        if response.status_code == 200:
            data = response.json()
            print(f"✓ Retrieved {data['data']['count']} services for host")
            return True
        else:
            print(f"✗ Failed to get services by host: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting services by host: {e}")
        return False


def test_generate_config():
    """Test config generation"""
    print("\n[TEST] Generate Config")

    try:
        response = requests.get(f"{API_BASE}/config/generate?environment=development")
        if response.status_code == 200:
            data = response.json()
            targets = data['data']['targets']
            print(f"✓ Generated config with {len(targets)} targets")

            if targets:
                print(f"\n  Sample target:")
                print(f"    Name: {targets[0].get('name')}")
                print(f"    Host: {targets[0].get('host')}")
                print(f"    Service: {targets[0].get('service')}")
                print(f"    SSH User: {targets[0]['ssh'].get('user')}")

            return True
        else:
            print(f"✗ Failed to generate config: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error generating config: {e}")
        return False


def test_dashboard_summary():
    """Test dashboard summary"""
    print("\n[TEST] Dashboard Summary")

    try:
        response = requests.get(f"{API_BASE}/services/dashboard/summary")
        if response.status_code == 200:
            data = response.json()['data']
            print(f"✓ Dashboard summary retrieved")
            print(f"  Total services: {data['total_services']}")
            print(f"  Running: {data['running_services']}")
            print(f"  Stopped: {data['stopped_services']}")
            print(f"  Error: {data['error_services']}")
            return True
        else:
            print(f"✗ Failed to get dashboard summary: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting dashboard summary: {e}")
        return False


def test_get_environments():
    """Test getting environments"""
    print("\n[TEST] Get Environments")

    try:
        response = requests.get(f"{API_BASE}/hosts/metadata/environments")
        if response.status_code == 200:
            envs = response.json()['data']['environments']
            print(f"✓ Retrieved {len(envs)} environments: {envs}")
            return True
        else:
            print(f"✗ Failed to get environments: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting environments: {e}")
        return False


def test_get_regions():
    """Test getting regions"""
    print("\n[TEST] Get Regions")

    try:
        response = requests.get(f"{API_BASE}/hosts/metadata/regions")
        if response.status_code == 200:
            regions = response.json()['data']['regions']
            print(f"✓ Retrieved {len(regions)} regions: {regions}")
            return True
        else:
            print(f"✗ Failed to get regions: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error getting regions: {e}")
        return False


def cleanup():
    """Cleanup test data"""
    print("\n[CLEANUP] Removing test data")

    try:
        # Delete service
        response = requests.delete(f"{API_BASE}/services/test_svc_001")
        if response.status_code == 200:
            print("✓ Test service deleted")

        # Delete host
        response = requests.delete(f"{API_BASE}/hosts/test_host_001")
        if response.status_code == 200:
            print("✓ Test host deleted")
    except Exception as e:
        print(f"⚠ Cleanup warning: {e}")


def main():
    """Run all tests"""
    print("="*60)
    print("Service Monitor API Integration Tests")
    print("="*60)

    print(f"\nAPI Base URL: {API_BASE}")
    print("Make sure the API is running: python api/main.py")

    tests = [
        test_health,
        test_create_host,
        test_get_hosts,
        test_get_specific_host,
        test_create_service,
        test_get_services,
        test_get_services_by_host,
        test_generate_config,
        test_dashboard_summary,
        test_get_environments,
        test_get_regions,
    ]

    results = []
    for test in tests:
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"✗ Test failed with exception: {e}")
            results.append(False)

    # Summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)
    passed = sum(results)
    total = len(results)
    print(f"\nPassed: {passed}/{total}")

    if passed == total:
        print("✓ All tests passed!")
    else:
        print(f"✗ {total - passed} test(s) failed")

    # Ask about cleanup
    if passed > 0:
        print("\nNote: Test data (test_host_001, test_svc_001) was created")
        response = input("Remove test data? (y/n): ").strip().lower()
        if response == 'y':
            cleanup()

    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
