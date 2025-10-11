import 'package:json_annotation/json_annotation.dart';

part 'log.g.dart';

@JsonSerializable()
class Log {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'service_name')
  final String serviceName;

  @JsonKey(name: 'service_type')
  final String? serviceType;

  @JsonKey(name: 'host')
  final String? host;

  @JsonKey(name: 'log_level')
  final String logLevel;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'timestamp')
  final String timestamp;

  @JsonKey(name: 'metadata')
  final Map<String, dynamic>? metadata;

  @JsonKey(name: 'tags')
  final List<String>? tags;

  @JsonKey(name: 'sent_to_user')
  final bool sentToUser;

  @JsonKey(name: 'date')
  final String date;

  @JsonKey(name: 'hour')
  final int hour;

  @JsonKey(name: 'service_key')
  final String serviceKey;

  Log({
    required this.id,
    required this.serviceName,
    this.serviceType,
    this.host,
    required this.logLevel,
    required this.message,
    required this.timestamp,
    this.metadata,
    this.tags,
    required this.sentToUser,
    required this.date,
    required this.hour,
    required this.serviceKey,
  });

  factory Log.fromJson(Map<String, dynamic> json) => _$LogFromJson(json);
  Map<String, dynamic> toJson() => _$LogToJson(this);
}

@JsonSerializable()
class LogsResponse {
  @JsonKey(name: 'total')
  final int total;

  @JsonKey(name: 'logs')
  final List<Log> logs;

  @JsonKey(name: 'filters')
  final LogFilters filters;

  LogsResponse({
    required this.total,
    required this.logs,
    required this.filters,
  });

  factory LogsResponse.fromJson(Map<String, dynamic> json) => _$LogsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogsResponseToJson(this);
}

@JsonSerializable()
class LogFilters {
  @JsonKey(name: 'service_name')
  final String? serviceName;

  @JsonKey(name: 'log_level')
  final String? logLevel;

  @JsonKey(name: 'hours')
  final int hours;

  @JsonKey(name: 'limit')
  final int limit;

  LogFilters({
    this.serviceName,
    this.logLevel,
    required this.hours,
    required this.limit,
  });

  factory LogFilters.fromJson(Map<String, dynamic> json) => _$LogFiltersFromJson(json);
  Map<String, dynamic> toJson() => _$LogFiltersToJson(this);
}
