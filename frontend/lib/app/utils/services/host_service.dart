import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/host.dart';
import '../helpers/api_response_handler.dart';

class HostService {
  /// Get all hosts with optional filters
  Future<HostListResponse> getHosts({
    String? environment,
    String? region,
    String? status,
    int limit = 100,
    int skip = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'skip': skip.toString(),
    };

    if (environment != null) {
      queryParams['environment'] = environment;
    }
    if (region != null) {
      queryParams['region'] = region;
    }
    if (status != null) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(
      '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hosts}',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<HostListResponse>(
      response,
      parser: (json) => HostListResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Get a specific host by ID
  Future<HostResponse> getHostById(String hostId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hosts}/$hostId'),
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<HostResponse>(
      response,
      parser: (json) => HostResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Create a new host
  Future<HostResponse> createHost({
    required String hostId,
    required String hostname,
    required String ipAddress,
    required String environment,
    required String region,
    HostLocation? location,
    required String sshUser,
    int sshPort = 22,
    String? sshKeyPath,
    bool useSudo = true,
    String? os,
    String? purpose,
    List<String>? tags,
    String status = 'active',
  }) async {
    final body = json.encode({
      'host_id': hostId,
      'hostname': hostname,
      'ip_address': ipAddress,
      'environment': environment,
      'region': region,
      if (location != null) 'location': location.toJson(),
      'ssh_config': {
        'user': sshUser,
        'port': sshPort,
        'key_path': sshKeyPath,
        'use_sudo': useSudo,
      },
      'metadata': {
        'os': os,
        'purpose': purpose,
        'tags': tags ?? [],
      },
      'status': status,
    });

    final response = await http.post(
      Uri.parse('${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hosts}'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return ApiResponseHandler.handleResponse<HostResponse>(
      response,
      parser: (json) => HostResponse.fromJson(json),
      operation: 'create',
    );
  }

  /// Update an existing host
  Future<HostResponse> updateHost({
    required String hostId,
    String? hostname,
    String? ipAddress,
    String? environment,
    String? region,
    HostLocation? location,
    String? sshUser,
    int? sshPort,
    String? sshKeyPath,
    bool? useSudo,
    String? os,
    String? purpose,
    List<String>? tags,
    String? status,
  }) async {
    final body = <String, dynamic>{};

    if (hostname != null) body['hostname'] = hostname;
    if (ipAddress != null) body['ip_address'] = ipAddress;
    if (environment != null) body['environment'] = environment;
    if (region != null) body['region'] = region;
    if (location != null) body['location'] = location.toJson();

    // SSH config
    if (sshUser != null || sshPort != null || sshKeyPath != null || useSudo != null) {
      body['ssh_config'] = <String, dynamic>{};
      if (sshUser != null) body['ssh_config']['user'] = sshUser;
      if (sshPort != null) body['ssh_config']['port'] = sshPort;
      if (sshKeyPath != null) body['ssh_config']['key_path'] = sshKeyPath;
      if (useSudo != null) body['ssh_config']['use_sudo'] = useSudo;
    }

    // Metadata
    if (os != null || purpose != null || tags != null) {
      body['metadata'] = <String, dynamic>{};
      if (os != null) body['metadata']['os'] = os;
      if (purpose != null) body['metadata']['purpose'] = purpose;
      if (tags != null) body['metadata']['tags'] = tags;
    }

    if (status != null) body['status'] = status;

    final response = await http.put(
      Uri.parse('${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hosts}/$hostId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    return ApiResponseHandler.handleResponse<HostResponse>(
      response,
      parser: (json) => HostResponse.fromJson(json),
      operation: 'update',
    );
  }

  /// Delete a host and optionally its services
  Future<void> deleteHost({
    required String hostId,
    bool deleteServices = false,
  }) async {
    final queryParams = <String, String>{};
    if (deleteServices) {
      queryParams['delete_services'] = 'true';
    }

    final uri = Uri.parse(
      '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hosts}/$hostId',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    ApiResponseHandler.handleEmptyResponse(
      response,
      operation: 'delete',
    );
  }

  /// Get all available environments
  Future<MetadataListResponse> getEnvironments() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hostsEnvironments}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<MetadataListResponse>(
      response,
      parser: (json) => MetadataListResponse.fromJson(json),
      operation: 'fetch',
    );
  }

  /// Get all available regions
  Future<MetadataListResponse> getRegions() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.monitoringBaseUrl}${ApiEndpoints.hostsRegions}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    return ApiResponseHandler.handleResponse<MetadataListResponse>(
      response,
      parser: (json) => MetadataListResponse.fromJson(json),
      operation: 'fetch',
    );
  }
}
