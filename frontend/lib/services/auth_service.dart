import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final StorageService _storage = StorageService();

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.login}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(AppConfig.requestTimeout);

      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

      if (authResponse.success && authResponse.data != null) {
        await _storage.saveAuthData(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.register}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        }),
      ).timeout(AppConfig.requestTimeout);

      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

      if (authResponse.success && authResponse.data != null) {
        await _storage.saveAuthData(authResponse.data!);
      }

      return authResponse;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
      );
    }
  }

  Future<bool> logout() async {
    try {
      final token = await _storage.getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.logout}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      // Continue with local logout even if API call fails
    }

    await _storage.clearAuthData();
    return true;
  }

  Future<User?> getCurrentUser() async {
    try {
      return await _storage.getUser();
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }
}