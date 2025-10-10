import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';
import '../../models/auth_response.dart';
import '../../models/user.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const _secureStorage = FlutterSecureStorage();

  Future<void> saveAuthData(AuthData authData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save tokens securely
    await _secureStorage.write(
      key: AppConfig.tokenKey,
      value: authData.accessToken,
    );
    await _secureStorage.write(
      key: AppConfig.refreshTokenKey,
      value: authData.refreshToken,
    );

    // Save user data in shared preferences
    await prefs.setString(
      AppConfig.userKey,
      jsonEncode(authData.user.toJson()),
    );
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConfig.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConfig.refreshTokenKey);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConfig.userKey);

    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.delete(key: AppConfig.tokenKey);
    await _secureStorage.delete(key: AppConfig.refreshTokenKey);
    await prefs.remove(AppConfig.userKey);
  }

  Future<void> saveUserPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getUserPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}