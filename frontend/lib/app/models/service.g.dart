// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Service _$ServiceFromJson(Map<String, dynamic> json) => Service(
  id: json['_id'] as String,
  totalLogs: (json['total_logs'] as num?)?.toInt() ?? 0,
  unsentLogs: (json['unsent_logs'] as num?)?.toInt() ?? 0,
  latestTimestamp: json['latest_timestamp'] as String?,
  latestStatus: json['latest_status'] as String?,
  latestLevel: json['latest_level'] as String?,
  serviceType: json['service_type'] as String?,
  host: json['host'] as String?,
);

Map<String, dynamic> _$ServiceToJson(Service instance) => <String, dynamic>{
  '_id': instance.id,
  'total_logs': instance.totalLogs,
  'unsent_logs': instance.unsentLogs,
  'latest_timestamp': instance.latestTimestamp,
  'latest_status': instance.latestStatus,
  'latest_level': instance.latestLevel,
  'service_type': instance.serviceType,
  'host': instance.host,
};

ServicesResponse _$ServicesResponseFromJson(Map<String, dynamic> json) =>
    ServicesResponse(
      totalServices: (100 as num).toInt(),
      services: (json['services'] as List<dynamic>)
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: json['last_updated'] as String,
    );

Map<String, dynamic> _$ServicesResponseToJson(ServicesResponse instance) =>
    <String, dynamic>{
      'total_services': instance.totalServices,
      'services': instance.services,
      'last_updated': instance.lastUpdated,
    };
