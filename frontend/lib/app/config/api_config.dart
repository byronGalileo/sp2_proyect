class ApiConfig {
  // Base URLs
  static const String mainBaseUrl = 'http://localhost:8000'; // Your main API
  static const String monitoringBaseUrl = 'http://192.168.2.2:8001'; // Monitoring API
}

class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';

  // User endpoints
  static const String users = '/users';
  static const String changePassword = '/users/change-password';

  // Database monitoring endpoints
  static const String databases = '/databases';
  static const String monitoring = '/monitoring';

  // Monitoring endpoints
  static const String services = '/services';
  static const String logs = '/logs';
}