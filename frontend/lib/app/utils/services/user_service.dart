import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/user.dart';
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
    try {
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

  /// Get user by ID
  Future<User> getUserById(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
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
    try {
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
    try {
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

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to update user');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deactivate user (soft delete)
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

  /// Activate user
  Future<User> activateUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/$userId/activate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to activate user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error activating user: $e');
    }
  }

  /// Assign roles to user
  Future<User> assignRoles({
    required int userId,
    required List<int> roleIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'role_ids': roleIds,
      });

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/$userId/assign-roles'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to assign roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error assigning roles: $e');
    }
  }

  /// Reset user password
  Future<User> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'new_password': newPassword,
      });

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/users/$userId/reset-password'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error resetting password: $e');
    }
  }
}
