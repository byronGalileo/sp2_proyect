import 'package:json_annotation/json_annotation.dart';

part 'service.g.dart';

@JsonSerializable()
class Service {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'total_logs', defaultValue: 0)
  final int totalLogs;

  @JsonKey(name: 'unsent_logs', defaultValue: 0)
  final int unsentLogs;

  @JsonKey(name: 'latest_timestamp')
  final String? latestTimestamp;

  @JsonKey(name: 'latest_status')
  final String? latestStatus;

  @JsonKey(name: 'latest_level')
  final String? latestLevel;

  @JsonKey(name: 'service_type')
  final String? serviceType;

  final String? host;

  Service({
    required this.id,
    required this.totalLogs,
    required this.unsentLogs,
    this.latestTimestamp,
    this.latestStatus,
    this.latestLevel,
    this.serviceType,
    this.host,
  });

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceToJson(this);
}

@JsonSerializable()
class ServicesResponse {
  @JsonKey(name: 'total_services')
  final int totalServices;

  final List<Service> services;

  @JsonKey(name: 'last_updated')
  final String lastUpdated;

  ServicesResponse({
    required this.totalServices,
    required this.services,
    required this.lastUpdated,
  });

  factory ServicesResponse.fromJson(Map<String, dynamic> json) =>
      _$ServicesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ServicesResponseToJson(this);
}
