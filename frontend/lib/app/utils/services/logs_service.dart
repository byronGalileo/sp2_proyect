import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/log.dart';
import '../../config/api_config.dart';

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

      final uri = Uri.parse('${ApiConfig.monitoringBaseUrl}${ApiEndpoints.logs}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return LogsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching logs: $e');
    }
  }
}
