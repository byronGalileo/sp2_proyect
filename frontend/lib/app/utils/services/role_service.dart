import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/role.dart';
import '../../models/permission.dart';
import 'storage_service.dart';
import '../helpers/api_response_handler.dart';

class RoleService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Get all roles
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

  /// Get single role by ID
  Future<Role> getRoleById(int roleId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/roles/$roleId'),
      headers: headers,
    );

    return ApiResponseHandler.handleResponse<Role>(
      response,
      parser: (json) => Role.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Create new role
  Future<Role> createRole({
    required String name,
    required String displayName,
    String? description,
    required List<int> permissionIds,
    bool isActive = true,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'name': name,
      'display_name': displayName,
      'description': description,
      'is_active': isActive,
      'permission_ids': permissionIds,
    });

    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/roles'),
      headers: headers,
      body: body,
    );

    return ApiResponseHandler.handleResponse<Role>(
      response,
      parser: (json) => Role.fromJson(json),
      operation: 'create',
    );
  }

  /// Update existing role
  Future<Role> updateRole({
    required int roleId,
    required String name,
    required String displayName,
    String? description,
    required List<int> permissionIds,
    required bool isActive,
  }) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'name': name,
      'display_name': displayName,
      'description': description,
      'is_active': isActive,
      'permission_ids': permissionIds,
    });

    final response = await http.put(
      Uri.parse('${AppConfig.baseUrl}/roles/$roleId'),
      headers: headers,
      body: body,
    );

    return ApiResponseHandler.handleResponse<Role>(
      response,
      parser: (json) => Role.fromJson(json),
      operation: 'update',
    );
  }

  /// Get all available permissions
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

  /// Get role permissions by role ID
  Future<List<Permission>> getRolePermissions(int roleId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/role-permissions?role_id=$roleId'),
      headers: headers,
    );

    return ApiResponseHandler.handleListResponse<Permission>(
      response,
      itemParser: (json) => Permission.fromJson(json),
      operation: 'fetch',
    );
  }
}
