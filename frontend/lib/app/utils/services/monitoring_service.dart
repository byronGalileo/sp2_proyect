import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/service.dart';
import '../../models/log.dart';
import '../../config/app_config.dart';
import '../helpers/api_response_handler.dart';
import 'storage_service.dart';

class MonitoringService {
  Future<ServicesResponse> getServices() async {
    try {
      final token = await StorageService().getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${AppConfig.monitoringBaseUrl}${ApiEndpoints.services}'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
      );

      return ApiResponseHandler.handleResponse<ServicesResponse>(
        response,
        parser: (json) => ServicesResponse.fromJson(json),
        operation: 'fetch services',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get unsent logs for a specific service
  /// Get unsent logs for a specific service
  Future<LogsResponse> getUnsentLogs({
    required String serviceName,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'service_name': serviceName,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${AppConfig.monitoringBaseUrl}/logs/unsent')
          .replace(queryParameters: queryParams);

      final token = await StorageService().getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
      );

      return ApiResponseHandler.handleResponse<LogsResponse>(
        response,
        parser: (json) => LogsResponse.fromJson(json),
        operation: 'fetch unsent logs',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Mark logs as sent
  /// Mark logs as sent
  Future<MarkLogsResponse> markLogsAsSent(List<String> logIds) async {
    try {
      final token = await StorageService().getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${AppConfig.monitoringBaseUrl}/logs/mark-sent'),
        headers: headers,
        body: json.encode({
          'log_ids': logIds,
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      return ApiResponseHandler.handleResponse<MarkLogsResponse>(
        response,
        parser: (json) => MarkLogsResponse.fromJson(json),
        operation: 'mark logs as sent',
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Response model for mark logs as sent
class MarkLogsResponse {
  final int markedCount;
  final String message;

  MarkLogsResponse({
    required this.markedCount,
    required this.message,
  });

  factory MarkLogsResponse.fromJson(Map<String, dynamic> json) {
    return MarkLogsResponse(
      markedCount: json['marked_count'] ?? json['updated_count'] ?? 0,
      message: json['message'] ?? 'Logs marked as sent',
    );
  }
}
