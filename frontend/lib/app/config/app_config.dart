import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Systems Monitor';
  static const String appVersion = '1.0.0';

  // API Configuration
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://192.168.3.216:8000/api/v1';
  static String get monitoringBaseUrl => dotenv.env['MONITORING_BASE_URL'] ?? 'http://192.168.3.216:8001';
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
  static const String services = '/services_summary';
  static const String logs = '/logs';

  // Host endpoints
  static const String hosts = '/hosts';
  static const String hostsEnvironments = '/hosts/metadata/environments';
  static const String hostsRegions = '/hosts/metadata/regions';

  // Managed Services endpoints
  static const String managedServices = '/services';
  static const String servicesDashboard = '/services/dashboard/summary';
  static const String servicesAttention = '/services/attention/needed';

  // Config generation endpoints
  static const String configGenerate = '/config/generate';

  // Monitoring execution endpoints
  static const String monitoringStart = '/monitoring/start';
  static const String monitoringStop = '/monitoring/stop';
  static const String monitoringStatus = '/monitoring/status';
}