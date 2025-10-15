import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/user.dart';
import '../helpers/api_response_handler.dart';
import 'storage_service.dart';

class UserListResponse {
  final List<User> users;
  final int total;
  final int skip;
  final int limit;

  UserListResponse({
    required this.users,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    final usersList = json['users'] as List<dynamic>?;
    return UserListResponse(
      users: usersList != null
          ? usersList
              .map((user) => User.fromJson(user as Map<String, dynamic>))
              .toList()
          : [],
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
    );
  }
}

class UserService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all users with pagination and filters
  Future<UserListResponse> getUsers({
    int skip = 0,
    int limit = 10,
    bool? isActive,
  }) async {
    final headers = await _getHeaders();

    // Build query parameters
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

    return ApiResponseHandler.handleResponse<UserListResponse>(
      response,
      parser: (json) => UserListResponse.fromJson(json),
      operation: 'fetch users',
    );
  }

  /// Get user by ID
  Future<User> getUserById(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/users/$userId'),
      headers: headers,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'fetch user',
    );
  }

  /// Create new user
  Future<User> createUser({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'username': username,
      'email': email,
      'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/create'),
      headers: headers,
      body: body,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'create user',
    );
  }

  /// Update user data
  Future<User> updateUser({
    required int userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/$userId/update'),
      headers: headers,
      body: body,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'update user',
    );
  }

  /// Deactivate user (soft delete)
  Future<User> deactivateUser(int userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/$userId/deactivate'),
      headers: headers,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'deactivate user',
    );
  }

  /// Activate user
  Future<User> activateUser(int userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/$userId/activate'),
      headers: headers,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'activate user',
    );
  }

  /// Assign roles to user
  Future<User> assignRoles({
    required int userId,
    required List<int> roleIds,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'role_ids': roleIds,
    });

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/$userId/assign-roles'),
      headers: headers,
      body: body,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'assign roles',
    );
  }

  /// Reset user password
  Future<User> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'new_password': newPassword,
    });

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/users/$userId/reset-password'),
      headers: headers,
      body: body,
    );

    return ApiResponseHandler.handleResponse<User>(
      response,
      parser: (json) => User.fromJson(json),
      operation: 'reset password',
    );
  }
}
