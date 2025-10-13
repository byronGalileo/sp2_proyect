// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ManagedService _$ManagedServiceFromJson(
  Map<String, dynamic> json,
) => ManagedService(
  id: json['_id'] as String?,
  serviceId: json['service_id'] as String,
  hostId: json['host_id'] as String,
  serviceName: json['service_name'] as String,
  serviceType: json['service_type'] as String,
  displayName: json['display_name'] as String?,
  description: json['description'] as String?,
  environment: json['environment'] as String,
  region: json['region'] as String,
  monitoring: ServiceMonitoring.fromJson(
    json['monitoring'] as Map<String, dynamic>,
  ),
  recovery: ServiceRecovery.fromJson(json['recovery'] as Map<String, dynamic>),
  alerting: ServiceAlerting.fromJson(json['alerting'] as Map<String, dynamic>),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  dependencies: (json['dependencies'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$ManagedServiceToJson(ManagedService instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'service_id': instance.serviceId,
      'host_id': instance.hostId,
      'service_name': instance.serviceName,
      'service_type': instance.serviceType,
      'display_name': instance.displayName,
      'description': instance.description,
      'environment': instance.environment,
      'region': instance.region,
      'monitoring': instance.monitoring,
      'recovery': instance.recovery,
      'alerting': instance.alerting,
      'tags': instance.tags,
      'dependencies': instance.dependencies,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'status': instance.status,
    };

ServiceMonitoring _$ServiceMonitoringFromJson(Map<String, dynamic> json) =>
    ServiceMonitoring(
      method: json['method'] as String,
      enabled: json['enabled'] as bool,
      intervalSec: (json['interval_sec'] as num).toInt(),
      timeoutSec: (json['timeout_sec'] as num).toInt(),
      retryAttempts: (json['retry_attempts'] as num).toInt(),
      retryDelaySec: (json['retry_delay_sec'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceMonitoringToJson(ServiceMonitoring instance) =>
    <String, dynamic>{
      'method': instance.method,
      'enabled': instance.enabled,
      'interval_sec': instance.intervalSec,
      'timeout_sec': instance.timeoutSec,
      'retry_attempts': instance.retryAttempts,
      'retry_delay_sec': instance.retryDelaySec,
    };

ServiceRecovery _$ServiceRecoveryFromJson(Map<String, dynamic> json) =>
    ServiceRecovery(
      recoverOnDown: json['recover_on_down'] as bool,
      recoverAction: json['recover_action'] as String,
      customScript: json['custom_script'] as String?,
      maxRecoveryAttempts: (json['max_recovery_attempts'] as num).toInt(),
      recoveryCooldownSec: (json['recovery_cooldown_sec'] as num).toInt(),
      notifyBeforeRecovery: json['notify_before_recovery'] as bool,
    );

Map<String, dynamic> _$ServiceRecoveryToJson(ServiceRecovery instance) =>
    <String, dynamic>{
      'recover_on_down': instance.recoverOnDown,
      'recover_action': instance.recoverAction,
      'custom_script': instance.customScript,
      'max_recovery_attempts': instance.maxRecoveryAttempts,
      'recovery_cooldown_sec': instance.recoveryCooldownSec,
      'notify_before_recovery': instance.notifyBeforeRecovery,
    };

ServiceAlerting _$ServiceAlertingFromJson(Map<String, dynamic> json) =>
    ServiceAlerting(
      enabled: json['enabled'] as bool,
      channels: (json['channels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      severity: json['severity'] as String,
    );

Map<String, dynamic> _$ServiceAlertingToJson(ServiceAlerting instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'channels': instance.channels,
      'severity': instance.severity,
    };

ManagedServiceListResponse _$ManagedServiceListResponseFromJson(
  Map<String, dynamic> json,
) => ManagedServiceListResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: ManagedServiceListData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ManagedServiceListResponseToJson(
  ManagedServiceListResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ManagedServiceListData _$ManagedServiceListDataFromJson(
  Map<String, dynamic> json,
) => ManagedServiceListData(
  services: (json['services'] as List<dynamic>)
      .map((e) => ManagedService.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$ManagedServiceListDataToJson(
  ManagedServiceListData instance,
) => <String, dynamic>{'services': instance.services, 'count': instance.count};

ManagedServiceResponse _$ManagedServiceResponseFromJson(
  Map<String, dynamic> json,
) => ManagedServiceResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: ManagedService.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ManagedServiceResponseToJson(
  ManagedServiceResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ServiceSummaryResponse _$ServiceSummaryResponseFromJson(
  Map<String, dynamic> json,
) => ServiceSummaryResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: ServiceSummaryData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ServiceSummaryResponseToJson(
  ServiceSummaryResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ServiceSummaryData _$ServiceSummaryDataFromJson(Map<String, dynamic> json) =>
    ServiceSummaryData(
      totalServices: (json['total_services'] as num).toInt(),
      runningServices: (json['running_services'] as num).toInt(),
      stoppedServices: (json['stopped_services'] as num).toInt(),
      errorServices: (json['error_services'] as num).toInt(),
      unknownServices: (json['unknown_services'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceSummaryDataToJson(ServiceSummaryData instance) =>
    <String, dynamic>{
      'total_services': instance.totalServices,
      'running_services': instance.runningServices,
      'stopped_services': instance.stoppedServices,
      'error_services': instance.errorServices,
      'unknown_services': instance.unknownServices,
    };
