import 'package:json_annotation/json_annotation.dart';

part 'managed_service.g.dart';

@JsonSerializable()
class ManagedService {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'service_id')
  final String serviceId;

  @JsonKey(name: 'host_id')
  final String hostId;

  @JsonKey(name: 'service_name')
  final String serviceName;

  @JsonKey(name: 'service_type')
  final String serviceType;

  @JsonKey(name: 'display_name')
  final String? displayName;

  final String? description;

  final String environment;

  final String region;

  final ServiceMonitoring monitoring;

  final ServiceRecovery recovery;

  final ServiceAlerting alerting;

  final List<String> tags;

  final List<String> dependencies;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  final String? status;

  ManagedService({
    this.id,
    required this.serviceId,
    required this.hostId,
    required this.serviceName,
    required this.serviceType,
    this.displayName,
    this.description,
    required this.environment,
    required this.region,
    required this.monitoring,
    required this.recovery,
    required this.alerting,
    required this.tags,
    required this.dependencies,
    this.createdAt,
    this.updatedAt,
    this.status,
  });

  factory ManagedService.fromJson(Map<String, dynamic> json) =>
      _$ManagedServiceFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedServiceToJson(this);
}

@JsonSerializable()
class ServiceMonitoring {
  final String method;
  final bool enabled;

  @JsonKey(name: 'interval_sec')
  final int intervalSec;

  @JsonKey(name: 'timeout_sec')
  final int timeoutSec;

  @JsonKey(name: 'retry_attempts')
  final int retryAttempts;

  @JsonKey(name: 'retry_delay_sec')
  final int retryDelaySec;

  ServiceMonitoring({
    required this.method,
    required this.enabled,
    required this.intervalSec,
    required this.timeoutSec,
    required this.retryAttempts,
    required this.retryDelaySec,
  });

  factory ServiceMonitoring.fromJson(Map<String, dynamic> json) =>
      _$ServiceMonitoringFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceMonitoringToJson(this);
}

@JsonSerializable()
class ServiceRecovery {
  @JsonKey(name: 'recover_on_down')
  final bool recoverOnDown;

  @JsonKey(name: 'recover_action')
  final String recoverAction;

  @JsonKey(name: 'custom_script')
  final String? customScript;

  @JsonKey(name: 'max_recovery_attempts')
  final int maxRecoveryAttempts;

  @JsonKey(name: 'recovery_cooldown_sec')
  final int recoveryCooldownSec;

  @JsonKey(name: 'notify_before_recovery')
  final bool notifyBeforeRecovery;

  ServiceRecovery({
    required this.recoverOnDown,
    required this.recoverAction,
    this.customScript,
    required this.maxRecoveryAttempts,
    required this.recoveryCooldownSec,
    required this.notifyBeforeRecovery,
  });

  factory ServiceRecovery.fromJson(Map<String, dynamic> json) =>
      _$ServiceRecoveryFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceRecoveryToJson(this);
}

@JsonSerializable()
class ServiceAlerting {
  final bool enabled;
  final List<String> channels;
  final String severity;

  ServiceAlerting({
    required this.enabled,
    required this.channels,
    required this.severity,
  });

  factory ServiceAlerting.fromJson(Map<String, dynamic> json) =>
      _$ServiceAlertingFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceAlertingToJson(this);
}

@JsonSerializable()
class ManagedServiceListResponse {
  final bool success;
  final String message;
  final ManagedServiceListData data;

  ManagedServiceListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ManagedServiceListResponse.fromJson(Map<String, dynamic> json) =>
      _$ManagedServiceListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedServiceListResponseToJson(this);
}

@JsonSerializable()
class ManagedServiceListData {
  final List<ManagedService> services;
  final int count;

  ManagedServiceListData({
    required this.services,
    required this.count,
  });

  factory ManagedServiceListData.fromJson(Map<String, dynamic> json) =>
      _$ManagedServiceListDataFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedServiceListDataToJson(this);
}

@JsonSerializable()
class ManagedServiceResponse {
  final bool success;
  final String message;
  final ManagedService data;

  ManagedServiceResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ManagedServiceResponse.fromJson(Map<String, dynamic> json) =>
      _$ManagedServiceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ManagedServiceResponseToJson(this);
}

@JsonSerializable()
class ServiceSummaryResponse {
  final bool success;
  final String message;
  final ServiceSummaryData data;

  ServiceSummaryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ServiceSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$ServiceSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceSummaryResponseToJson(this);
}

@JsonSerializable()
class ServiceSummaryData {
  @JsonKey(name: 'total_services')
  final int totalServices;

  @JsonKey(name: 'running_services')
  final int runningServices;

  @JsonKey(name: 'stopped_services')
  final int stoppedServices;

  @JsonKey(name: 'error_services')
  final int errorServices;

  @JsonKey(name: 'unknown_services')
  final int unknownServices;

  ServiceSummaryData({
    required this.totalServices,
    required this.runningServices,
    required this.stoppedServices,
    required this.errorServices,
    required this.unknownServices,
  });

  factory ServiceSummaryData.fromJson(Map<String, dynamic> json) =>
      _$ServiceSummaryDataFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceSummaryDataToJson(this);
}
