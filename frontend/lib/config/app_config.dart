class AppConfig {
  static const String appName = 'Systems Monitor';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // UI Constants
  static const double borderRadius = 12.0;
  static const double padding = 16.0;
  static const double buttonHeight = 48.0;
}