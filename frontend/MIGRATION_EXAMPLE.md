# UserService Migration Example

This file shows how to migrate UserService methods to use the new error handling system.

## Add Import

First, add the import at the top of user_service.dart:

```dart
import '../helpers/api_response_handler.dart';
```

## Example Migrations

### 1. getUsers (Paginated Response)

**Before:**
```dart
Future<UserListResponse> getUsers({
  int skip = 0,
  int limit = 10,
  bool? isActive,
}) async {
  try {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final uri = Uri.parse('${AppConfig.baseUrl}/users/').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);
      return UserListResponse.fromJson(decodedBody);
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching users: $e');
  }
}
```

**After:**
```dart
Future<UserListResponse> getUsers({
  int skip = 0,
  int limit = 10,
  bool? isActive,
}) async {
  final headers = await _getHeaders();
  final queryParams = <String, String>{
    'skip': skip.toString(),
    'limit': limit.toString(),
  };

  if (isActive != null) {
    queryParams['is_active'] = isActive.toString();
  }

  final uri = Uri.parse('${AppConfig.baseUrl}/users/').replace(
    queryParameters: queryParams,
  );

  final response = await http.get(uri, headers: headers);

  final json = ApiResponseHandler.handlePaginatedResponse(
    response,
    operation: 'fetch',
  );

  return UserListResponse.fromJson(json);
}
```

### 2. createUser (with error details)

**Before:**
```dart
Future<User> createUser({
  required String username,
  required String email,
  required String password,
  String? firstName,
  String? lastName,
}) async {
  try {
    final headers = await _getHeaders();
    final body = json.encode({
      'username': username,
      'email': email,
      'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/create'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(json.decode(response.body));
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['detail'] ?? 'Failed to create user');
    }
  } catch (e) {
    rethrow;
  }
}
```

**After:**
```dart
Future<User> createUser({
  required String username,
  required String email,
  required String password,
  String? firstName,
  String? lastName,
}) async {
  final headers = await _getHeaders();
  final body = json.encode({
    'username': username,
    'email': email,
    'password': password,
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
  });

  final response = await http.post(
    Uri.parse('${AppConfig.baseUrl}/users/create'),
    headers: headers,
    body: body,
  );

  return ApiResponseHandler.handleResponse<User>(
    response,
    parser: (json) => User.fromJson(json),
    operation: 'create',
  );
}
```

### 3. deactivateUser (Empty Response)

**Before:**
```dart
Future<User> deactivateUser(int userId) async {
  try {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/$userId/deactivate'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to deactivate user: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error deactivating user: $e');
  }
}
```

**After:**
```dart
Future<User> deactivateUser(int userId) async {
  final headers = await _getHeaders();
  final response = await http.post(
    Uri.parse('${AppConfig.baseUrl}/users/$userId/deactivate'),
    headers: headers,
  );

  return ApiResponseHandler.handleResponse<User>(
    response,
    parser: (json) => User.fromJson(json),
    operation: 'update',
  );
}
```

## Error Messages You'll Get

With the new system, when errors occur, users will see:

### 401 Unauthorized (Fetch)
"You don't have permission to view this resource."

### 401 Unauthorized (Create)
"You don't have permission to create this resource."

### 403 Forbidden
"Access forbidden. You don't have the necessary permissions."

### 404 Not Found
"Resource not found. The requested item doesn't exist."

### 422 Validation Error
"Validation error. Please check your input."
(Plus any details from the server response)

### 500 Server Error
"Internal server error. Please try again later."

## Controller Error Handling

Update your controllers to handle the new ApiException:

```dart
import '../utils/exceptions/api_exception.dart';

class UsersController extends GetxController {
  Future<void> createUser() async {
    try {
      final user = await _userService.createUser(
        username: usernameController.text,
        email: emailController.text,
        password: passwordController.text,
      );

      Get.snackbar('Success', 'User created successfully');
      Get.back();

    } on ApiException catch (e) {
      Get.snackbar(
        'Error',
        e.message,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );

      // Handle specific error types
      if (e.isAuthError) {
        // Session expired, redirect to login
        Get.offAllNamed('/login');
      } else if (e.isValidationError && e.details != null) {
        // Show detailed validation errors
        print('Validation details: ${e.details}');
      }

    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
    }
  }
}
```

## Benefits

1. **Cleaner Code**: No more nested try-catch blocks
2. **Consistent Messages**: All API errors have user-friendly messages
3. **Better UX**: Users see helpful error descriptions
4. **Easier Debugging**: Error details are preserved
5. **Type-Safe**: Can check error types with convenience methods
