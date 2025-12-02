# System Monitor API Documentation

This document provides a comprehensive guide to the System Monitor API. The API is built using FastAPI and provides endpoints for user management, role-based access control (RBAC), database connection management, and system monitoring.

## Base URL

The API is served at `/api/v1`.
For local development, the base URL is typically `http://localhost:8000/api/v1`.

## Authentication

The API uses Bearer Token authentication. You must obtain an access token by logging in and include it in the `Authorization` header of your requests.

**Header Format:**
```
Authorization: Bearer <your_access_token>
```

## Endpoints

### 1. Authentication (`/auth`)

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `POST` | `/register` | Register a new user account. | Public |
| `POST` | `/login` | Authenticate a user and retrieve access and refresh tokens. | Public |
| `POST` | `/logout` | Logout the current user (client should discard tokens). | Authenticated |

### 2. Users (`/users`)

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/profile` | Get the profile of the currently logged-in user. | Authenticated |
| `POST` | `/profile` | Update the profile of the currently logged-in user. | Authenticated |
| `GET` | `/` | Get a list of all users. | Admin/Super Admin |
| `GET` | `/{user_id}` | Get details of a specific user by ID. | Admin/Super Admin |
| `POST` | `/create` | Create a new user manually. | Admin/Super Admin |
| `POST` | `/{user_id}/update` | Update a specific user's data. | Admin/Super Admin |
| `POST` | `/{user_id}/deactivate` | Deactivate a user account. | Admin/Super Admin |
| `POST` | `/{user_id}/activate` | Activate a user account. | Admin/Super Admin |
| `POST` | `/{user_id}/assign-roles` | Assign roles to a user. | Admin/Super Admin |
| `POST` | `/{user_id}/reset-password` | Reset a user's password. | Admin/Super Admin |

### 3. Roles (`/roles`)

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Get a list of all defined roles. | Authenticated |
| `GET` | `/{role_id}` | Get details of a specific role. | Authenticated |
| `POST` | `/` | Create a new role. | Authenticated |
| `PUT` | `/{role_id}` | Update an existing role. | Authenticated |
| `DELETE` | `/{role_id}` | Delete (soft delete) a role. | Authenticated |

### 4. Permissions (`/permissions`)

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Get a list of all permissions. | Authenticated |
| `GET` | `/{permission_id}` | Get details of a specific permission. | Authenticated |
| `POST` | `/` | Create a new permission. | Authenticated |
| `POST` | `/{permission_id}` | Update an existing permission. | Authenticated |

### 5. Role Permissions (`/role-permissions`)

| Method | Endpoint | Description | Access |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Get all role-permission assignments. Supports filtering by `role_id` or `permission_id`. | Authenticated |
| `GET` | `/{role_permission_id}` | Get a specific role-permission assignment. | Authenticated |
| `POST` | `/` | Assign a permission to a role. | Authenticated |
| `POST` | `/{role_permission_id}` | Update a role-permission assignment. | Authenticated |

## Data Models

### User Object
```json
{
  "id": 1,
  "username": "jdoe",
  "email": "jdoe@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "is_active": true,
  "roles": ["admin", "user"]
}
```

### Auth Response
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { ... },
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_in": 3600
  }
}
```
