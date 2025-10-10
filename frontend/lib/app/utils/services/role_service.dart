import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/role.dart';
import '../../models/permission.dart';
import 'storage_service.dart';

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
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/roles'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final roles = <Role>[];
        for (var i = 0; i < data.length; i++) {
          try {
            final role = Role.fromJson(data[i]);
            roles.add(role);
          } catch (e) {
            rethrow;
          }
        }
        return roles;
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching roles: $e');
    }
  }

  /// Get single role by ID
  Future<Role> getRoleById(int roleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/roles/$roleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Role.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching role: $e');
    }
  }

  /// Create new role
  Future<Role> createRole({
    required String name,
    required String displayName,
    String? description,
    required List<int> permissionIds,
    bool isActive = true,
  }) async {
    try {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Role.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating role: $e');
    }
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
    try {
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

      if (response.statusCode == 200) {
        return Role.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating role: $e');
    }
  }

  /// Get all available permissions
  Future<List<Permission>> getPermissions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/permissions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Permission.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load permissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching permissions: $e');
    }
  }

  /// Get role permissions by role ID
  Future<List<Permission>> getRolePermissions(int roleId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/role-permissions?role_id=$roleId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Permission.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load role permissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching role permissions: $e');
    }
  }
}
