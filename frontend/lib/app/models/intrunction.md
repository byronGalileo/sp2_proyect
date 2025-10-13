we deffined this: 
help me to integrate a new enpoint to manage hosts: 
CRUD operations for host management:
monitoringBaseUrl
- POST /hosts - Create new host
- GET /hosts - Get specific host
- GET /hosts?environment=production&region=us-east-1&status=active&limit=100&skip=0 - Get all hosts with filters
- PUT /hosts/{host_id} - Update host information
- DELETE /hosts/{host_id}?delete_services=true - Delete host and optionally its services
- GET /hosts/metadata/environments - List all environments
- GET /hosts/metadata/regions - List all regions

Schema of hosts: 
{
  "success": true,
  "message": "Retrieved 1 hosts",
  "data": {
    "hosts": [
      {
        "_id": "68ec4ed2c8492fcb4a563c4e",
        "host_id": "host_web_001",
        "hostname": "web-server",
        "ip_address": "192.168.1.100",
        "environment": "production",
        "region": "us-east-1",
        "location": {},
        "ssh_config": {
          "user": "ubuntu",
          "port": 22,
          "key_path": null,
          "use_sudo": true
        },
        "metadata": {
          "os": null,
          "purpose": null,
          "tags": [
            "nginx",
            "web"
          ]
        },
        "status": "active",
        "created_at": "2025-10-13T00:58:58.826000",
        "updated_at": "2025-10-13T00:58:58.826000",
        "last_seen": "2025-10-13T00:58:58.826000"
      }
    ],
    "count": 1
  }
}

steps defined, can you continue with the pending steps: 
- Create HostsController for managing host state, done
- Create hosts screen with CRUD operations, done
- Create host card widget for mobile view, done
- Create host table widget for desktop/tablet view, done
- Create host form dialog for create/edit, done
- Add route for hosts screen, pending
- Update sidebar navigation to include Admin Services, pending