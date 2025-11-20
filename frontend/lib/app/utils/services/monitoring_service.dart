import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/service.dart';
import '../../models/log.dart';
import '../../config/api_config.dart';

class MonitoringService {
  Future<ServicesResponse> getServices() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.monitoringBaseUrl}${ApiEndpoints.services}'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ServicesResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching services: $e');
    }
  }

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

      final uri = Uri.parse('${ApiConfig.monitoringBaseUrl}/logs/unsent')
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
        throw Exception('Failed to load unsent logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching unsent logs: $e');
    }
  }

  /// Mark logs as sent
  Future<MarkLogsResponse> markLogsAsSent(List<String> logIds) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.monitoringBaseUrl}/logs/mark-sent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'log_ids': logIds,
        }),
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MarkLogsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to mark logs as sent: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking logs as sent: $e');
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
