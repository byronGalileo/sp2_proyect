import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/log.dart';
import '../../config/app_config.dart';
import '../helpers/api_response_handler.dart';
import 'storage_service.dart';

class LogsService {
  Future<LogsResponse> getLogs({
    String? serviceName,
    String? logLevel,
    int hours = 24,
    int limit = 100,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'hours': hours.toString(),
        'limit': limit.toString(),
      };

      if (serviceName != null && serviceName.isNotEmpty) {
        queryParams['service_name'] = serviceName;
      }

      if (logLevel != null && logLevel.isNotEmpty && logLevel != 'ALL') {
        queryParams['log_level'] = logLevel;
      }

      final uri = Uri.parse('${AppConfig.monitoringBaseUrl}${ApiEndpoints.logs}')
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
        operation: 'fetch logs',
      );
    } catch (e) {
      rethrow;
    }
  }
}
