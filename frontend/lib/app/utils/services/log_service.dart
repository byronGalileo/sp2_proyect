import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/log.dart';
import '../helpers/api_response_handler.dart';

class LogService {
  /// Get logs with optional filters
  Future<LogsResponse> getLogs({
    String? serviceName,
    String? logLevel,
    int hours = 24,
    int limit = 1000,
  }) async {
    final queryParams = <String, String>{
      'hours': hours.toString(),
      'limit': limit.toString(),
    };

    if (serviceName != null) {
      queryParams['service_name'] = serviceName;
    }
    if (logLevel != null) {
      queryParams['log_level'] = logLevel;
    }

    final uri = Uri.parse(
      '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.logs}',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<LogsResponse>(
      response,
      parser: (json) => LogsResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Aggregate logs by level and time for charting
  Map<String, List<LogDataPoint>> aggregateLogsByLevelAndTime(
    List<Log> logs,
    int hours,
  ) {
    final now = DateTime.now();
    final startTime = now.subtract(Duration(hours: hours));

    // Determine bucket size based on time period
    final int bucketMinutes = _getBucketSizeInMinutes(hours);
    final int totalBuckets = (hours * 60 / bucketMinutes).ceil();

    // Create time buckets
    final Map<String, Map<DateTime, int>> levelBuckets = {
      'INFO': {},
      'WARNING': {},
      'ERROR': {},
      'CRITICAL': {},
    };

    // Initialize buckets for each time interval
    for (var i = 0; i <= totalBuckets; i++) {
      final bucketTime = startTime.add(Duration(minutes: i * bucketMinutes));
      for (var level in levelBuckets.keys) {
        levelBuckets[level]![bucketTime] = 0;
      }
    }

    // Count logs in each bucket
    for (var log in logs) {
      try {
        final logTime = DateTime.parse(log.timestamp);
        final level = log.logLevel.toUpperCase();

        if (logTime.isBefore(startTime) || logTime.isAfter(now)) {
          continue;
        }

        // Find the appropriate bucket by rounding down to nearest bucket time
        final minutesSinceStart = logTime.difference(startTime).inMinutes;
        final bucketIndex = (minutesSinceStart / bucketMinutes).floor();
        final bucketTime =
            startTime.add(Duration(minutes: bucketIndex * bucketMinutes));

        if (levelBuckets.containsKey(level) &&
            levelBuckets[level]!.containsKey(bucketTime)) {
          levelBuckets[level]![bucketTime] =
              (levelBuckets[level]![bucketTime] ?? 0) + 1;
        }
      } catch (e) {
        // Skip invalid timestamps
      }
    }

    // Convert to LogDataPoint list
    final Map<String, List<LogDataPoint>> result = {};
    levelBuckets.forEach((level, buckets) {
      result[level] = buckets.entries
          .map((e) => LogDataPoint(timestamp: e.key, count: e.value))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    return result;
  }

  /// Determine bucket size based on time period
  /// - 6h → 30 minutes
  /// - 12h → 60 minutes
  /// - 24h → 120 minutes (2 hours)
  /// - 48h → 240 minutes (4 hours)
  /// - 168h (7 days) → 1440 minutes (1 day)
  int _getBucketSizeInMinutes(int hours) {
    if (hours <= 6) return 30; // 30 minutes
    if (hours <= 12) return 60; // 1 hour
    if (hours <= 24) return 120; // 2 hours
    if (hours <= 48) return 240; // 4 hours
    return 1440; // 1 day
  }
}

class LogDataPoint {
  final DateTime timestamp;
  final int count;

  LogDataPoint({required this.timestamp, required this.count});
}
