// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Log _$LogFromJson(Map<String, dynamic> json) => Log(
  id: json['id'] as String,
  serviceName: json['service_name'] as String,
  serviceType: json['service_type'] as String?,
  host: json['host'] as String?,
  logLevel: json['log_level'] as String,
  message: json['message'] as String,
  timestamp: json['timestamp'] as String,
  metadata: json['metadata'] as Map<String, dynamic>?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  sentToUser: json['sent_to_user'] as bool,
  date: json['date'] as String,
  hour: (json['hour'] as num).toInt(),
  serviceKey: json['service_key'] as String,
);

Map<String, dynamic> _$LogToJson(Log instance) => <String, dynamic>{
  'id': instance.id,
  'service_name': instance.serviceName,
  'service_type': instance.serviceType,
  'host': instance.host,
  'log_level': instance.logLevel,
  'message': instance.message,
  'timestamp': instance.timestamp,
  'metadata': instance.metadata,
  'tags': instance.tags,
  'sent_to_user': instance.sentToUser,
  'date': instance.date,
  'hour': instance.hour,
  'service_key': instance.serviceKey,
};

LogsResponse _$LogsResponseFromJson(Map<String, dynamic> json) => LogsResponse(
  total: (json['total'] as num).toInt(),
  logs: (json['logs'] as List<dynamic>)
      .map((e) => Log.fromJson(e as Map<String, dynamic>))
      .toList(),
  filters: LogFilters.fromJson(json['filters'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LogsResponseToJson(LogsResponse instance) =>
    <String, dynamic>{
      'total': instance.total,
      'logs': instance.logs,
      'filters': instance.filters,
    };

LogFilters _$LogFiltersFromJson(Map<String, dynamic> json) => LogFilters(
  serviceName: json['service_name'] as String?,
  logLevel: json['log_level'] as String?,
  hours: (json['hours'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$LogFiltersToJson(LogFilters instance) =>
    <String, dynamic>{
      'service_name': instance.serviceName,
      'log_level': instance.logLevel,
      'hours': instance.hours,
      'limit': instance.limit,
    };
