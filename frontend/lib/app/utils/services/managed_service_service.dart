import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/managed_service.dart';
import '../helpers/api_response_handler.dart';

class ManagedServiceService {
  /// Get all services with optional filters
  Future<ManagedServiceListResponse> getServices({
    String? hostId,
    String? serviceType,
    String? environment,
    String? region,
    String? status,
    bool? enabledOnly,
    int limit = 100,
    int skip = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'skip': skip.toString(),
    };

    if (hostId != null) {
      queryParams['host_id'] = hostId;
    }
    if (serviceType != null) {
      queryParams['service_type'] = serviceType;
    }
    if (environment != null) {
      queryParams['environment'] = environment;
    }
    if (region != null) {
      queryParams['region'] = region;
    }
    if (status != null) {
      queryParams['status'] = status;
    }
    if (enabledOnly != null) {
      queryParams['enabled_only'] = enabledOnly.toString();
    }

    final uri = Uri.parse(
      '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.managedServices}',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<ManagedServiceListResponse>(
      response,
      parser: (json) => ManagedServiceListResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Get a specific service by ID
  Future<ManagedServiceResponse> getServiceById(String serviceId) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.managedServices}/$serviceId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<ManagedServiceResponse>(
      response,
      parser: (json) => ManagedServiceResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Create a new service
  Future<void> createService({
    String? serviceId,
    required String hostId,
    required String serviceName,
    required String serviceType,
    String? displayName,
    String? description,
    required String environment,
    required String region,
    required ServiceMonitoring monitoring,
    required ServiceRecovery recovery,
    required ServiceAlerting alerting,
    List<String>? tags,
    List<String>? dependencies,
  }) async {
    final body = json.encode({
      if (serviceId != null) 'service_id': serviceId,
      'host_id': hostId,
      'service_name': serviceName,
      'service_type': serviceType,
      if (displayName != null) 'display_name': displayName,
      if (description != null) 'description': description,
      'environment': environment,
      'region': region,
      'monitoring': monitoring.toJson(),
      'recovery': recovery.toJson(),
      'alerting': alerting.toJson(),
      'tags': tags ?? [],
      'dependencies': dependencies ?? [],
    });

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.managedServices}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    ApiResponseHandler.handleEmptyResponse(
      response,
      operation: 'create',
    );
  }

  /// Update an existing service
  Future<void> updateService({
    required String serviceId,
    String? hostId,
    String? serviceName,
    String? serviceType,
    String? displayName,
    String? description,
    String? environment,
    String? region,
    ServiceMonitoring? monitoring,
    ServiceRecovery? recovery,
    ServiceAlerting? alerting,
    List<String>? tags,
    List<String>? dependencies,
    String? status,
  }) async {
    final body = <String, dynamic>{};

    if (hostId != null) body['host_id'] = hostId;
    if (serviceName != null) body['service_name'] = serviceName;
    if (serviceType != null) body['service_type'] = serviceType;
    if (displayName != null) body['display_name'] = displayName;
    if (description != null) body['description'] = description;
    if (environment != null) body['environment'] = environment;
    if (region != null) body['region'] = region;
    if (monitoring != null) body['monitoring'] = monitoring.toJson();
    if (recovery != null) body['recovery'] = recovery.toJson();
    if (alerting != null) body['alerting'] = alerting.toJson();
    if (tags != null) body['tags'] = tags;
    if (dependencies != null) body['dependencies'] = dependencies;
    if (status != null) body['status'] = status;

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.managedServices}/$serviceId',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    ApiResponseHandler.handleEmptyResponse(
      response,
      operation: 'update',
    );
  }

  /// Delete a service
  Future<void> deleteService(String serviceId) async {
    final response = await http.delete(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.managedServices}/$serviceId',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    ApiResponseHandler.handleEmptyResponse(
      response,
      operation: 'delete',
    );
  }

  /// Get dashboard summary
  Future<ServiceSummaryResponse> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.servicesDashboard}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<ServiceSummaryResponse>(
      response,
      parser: (json) => ServiceSummaryResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Get services needing attention
  Future<ManagedServiceListResponse> getServicesNeedingAttention() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.servicesAttention}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<ManagedServiceListResponse>(
      response,
      parser: (json) => ManagedServiceListResponse.fromJson(json),
      operation: 'fetch',
    );
  }
}
