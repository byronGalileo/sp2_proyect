# API Error Handling Guide

This guide explains how to use the custom error handling system for API responses.

## Overview

The error handling system consists of two main components:

1. **ApiException** - Custom exception class with user-friendly messages
2. **ApiResponseHandler** - Utility class for handling HTTP responses

## Custom Error Messages

The system provides user-friendly error messages for all HTTP status codes:

### Client Errors (4xx)
- **400**: "Bad request. Please check your input and try again."
- **401**: "You don't have permission for this resource. Please log in again."
- **403**: "Access forbidden. You don't have the necessary permissions."
- **404**: "Resource not found. The requested item doesn't exist."
- **409**: "Conflict. This resource already exists or conflicts with another."
- **422**: "Validation error. Please check your input."
- **429**: "Too many requests. Please slow down and try again later."

### Server Errors (5xx)
- **500**: "Internal server error. Please try again later."
- **502**: "Bad gateway. The server is temporarily unavailable."
- **503**: "Service unavailable. Please try again later."
- **504**: "Gateway timeout. The server took too long to respond."

## Usage Examples

### Before (Old Way)

```dart
Future<List<Role>> getRoles() async {
  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/roles'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Role.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load roles: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching roles: $e');
  }
}
```

### After (New Way)

```dart
Future<List<Role>> getRoles() async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/roles'),
    headers: headers,
  );

  return ApiResponseHandler.handleListResponse<Role>(
    response,
    itemParser: (json) => Role.fromJson(json),
    operation: 'fetch',
  );
}
```

## Operation Types

Use the appropriate operation type for better error messages:

- **'fetch'**: For GET requests (reading data)
- **'create'**: For POST requests (creating resources)
- **'update'**: For PUT/PATCH requests (updating resources)
- **'delete'**: For DELETE requests (deleting resources)

### Operation-Specific Error Messages

The system provides operation-specific messages:

#### Create Operation (401)
"You don't have permission to create this resource."

#### Update Operation (404)
"Resource not found. Cannot update a non-existent item."

#### Delete Operation (403)
"Access forbidden. You cannot delete this resource."

## Handling Different Response Types

### Single Object Response

```dart
Future<User> getUserById(int userId) async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/users/$userId'),
    headers: headers,
  );

  return ApiResponseHandler.handleResponse<User>(
    response,
    parser: (json) => User.fromJson(json),
    operation: 'fetch',
  );
}
```

### List Response

```dart
Future<List<Permission>> getPermissions() async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/permissions'),
    headers: headers,
  );

  return ApiResponseHandler.handleListResponse<Permission>(
    response,
    itemParser: (json) => Permission.fromJson(json),
    operation: 'fetch',
  );
}
```

### Paginated Response

```dart
Future<UserListResponse> getUsers() async {
  final headers = await _getHeaders();
  final response = await http.get(
    Uri.parse('${AppConfig.baseUrl}/users'),
    headers: headers,
  );

  final json = ApiResponseHandler.handlePaginatedResponse(
    response,
    operation: 'fetch',
  );

  return UserListResponse.fromJson(json);
}
```

### Empty Response (No return value)

```dart
Future<void> activateUser(int userId) async {
  final headers = await _getHeaders();
  final response = await http.post(
    Uri.parse('${AppConfig.baseUrl}/users/$userId/activate'),
    headers: headers,
  );

  ApiResponseHandler.handleEmptyResponse(
    response,
    operation: 'update',
  );
}
```

## Catching and Displaying Errors

In your controllers or UI layer:

```dart
try {
  await roleService.createRole(
    name: 'admin',
    displayName: 'Administrator',
    permissionIds: [1, 2, 3],
  );

  Get.snackbar('Success', 'Role created successfully');

} on ApiException catch (e) {
  // Display user-friendly error message
  Get.snackbar('Error', e.message);

  // Check error type
  if (e.isAuthError) {
    // Redirect to login
    Get.offAllNamed('/login');
  } else if (e.isValidationError) {
    // Highlight form errors
    print('Validation details: ${e.details}');
  }

} catch (e) {
  // Handle other errors
  Get.snackbar('Error', 'An unexpected error occurred');
}
```

## ApiException Properties

```dart
final exception = ApiException.fromStatusCode(401);

// Properties
exception.statusCode      // 401
exception.message         // "You don't have permission..."
exception.details         // Additional details from server
exception.shortMessage    // Message without details

// Convenience methods
exception.isAuthError        // true for 401
exception.isPermissionError  // true for 403
exception.isNotFoundError    // true for 404
exception.isValidationError  // true for 400 or 422
exception.isServerError      // true for 5xx
exception.isClientError      // true for 4xx
```

## Migration Checklist

To migrate existing services:

1. Add import:
   ```dart
   import '../helpers/api_response_handler.dart';
   ```

2. Remove try-catch blocks from service methods

3. Replace manual response handling with ApiResponseHandler calls

4. Specify the appropriate operation type

5. Update error handling in controllers to catch ApiException

## Benefits

- ✅ Consistent error messages across the app
- ✅ User-friendly error descriptions
- ✅ Less boilerplate code in services
- ✅ Operation-specific error messages
- ✅ Easy error type checking
- ✅ Better error details from server responses
- ✅ Cleaner, more maintainable code
