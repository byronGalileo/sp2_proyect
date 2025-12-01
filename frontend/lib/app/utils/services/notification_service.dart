import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_config.dart';
import '../../config/routes/app_pages.dart';
import '../../config/themes/app_theme.dart';
import '../../models/notification_config.dart';
import '../exceptions/api_exception.dart';
import 'storage_service.dart';

class NotificationService {
  final Dio _dio;

  NotificationService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.monitoringBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService().getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          StorageService().clearAuthData().then((_) {
            Get.offAllNamed(Routes.login);
            Get.snackbar(
              'Session Expired',
              'Please log in again',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.error.withOpacity(0.1),
              colorText: AppColors.error,
              margin: const EdgeInsets.all(16),
            );
          });
        } else if (e.response?.statusCode == 403) {
          if (Get.currentRoute != Routes.home) {
            Get.offNamed(Routes.home);
            Get.snackbar(
              'Access Denied',
              'You do not have permission to access this resource',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.warning.withOpacity(0.1),
              colorText: AppColors.warning,
              margin: const EdgeInsets.all(16),
            );
          }
        }
        return handler.next(e);
      },
    ));
  }

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
