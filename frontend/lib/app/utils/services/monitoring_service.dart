import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/service.dart';
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
}
