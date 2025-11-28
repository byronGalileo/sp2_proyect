import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../models/notification_config.dart';
import '../exceptions/api_exception.dart';

class NotificationService {
  final Dio _dio;

  NotificationService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.monitoringBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<List<NotificationConfig>> getConfigs() async {
    try {
      final response = await _dio.get('/notifications/configs');
      return (response.data as List)
          .map((e) => NotificationConfig.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NotificationConfig> getConfig(String serviceId, String host) async {
    try {
      final response = await _dio.get(
        '/notifications/configs/$serviceId',
        queryParameters: {'host': host},
      );
      return NotificationConfig.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createConfig(NotificationConfig config) async {
    try {
      await _dio.post(
        '/notifications/configs',
        data: config.toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateSettings(
      String serviceId, String host, String smsProvider, int cooldown) async {
    try {
      await _dio.patch(
        '/notifications/configs/$serviceId/settings',
        queryParameters: {
          'host': host,
          'sms_provider': smsProvider,
          'cooldown_minutes': cooldown,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateStatus(
      String serviceId, String host, bool enabled) async {
    try {
      await _dio.put(
        '/notifications/configs/$serviceId/status',
        queryParameters: {
          'host': host,
          'enabled': enabled,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addContact(
      String serviceId, String host, Contact contact) async {
    try {
      await _dio.post(
        '/notifications/configs/$serviceId/contacts',
        queryParameters: {'host': host},
        data: contact.toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateContact(
      String serviceId, String host, String contactName, Contact contact) async {
    try {
      await _dio.put(
        '/notifications/configs/$serviceId/contacts/$contactName',
        queryParameters: {'host': host},
        data: contact.toJson(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteContact(
      String serviceId, String host, String contactName) async {
    try {
      await _dio.delete(
        '/notifications/configs/$serviceId/contacts/$contactName',
        queryParameters: {'host': host},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteConfig(String serviceId, String host) async {
    try {
      await _dio.delete(
        '/notifications/configs/$serviceId',
        queryParameters: {'host': host},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
