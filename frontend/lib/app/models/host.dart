import 'package:json_annotation/json_annotation.dart';

part 'host.g.dart';

@JsonSerializable()
class Host {
  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'host_id')
  final String hostId;

  final String hostname;

  @JsonKey(name: 'ip_address')
  final String ipAddress;

  final String environment;

  final String region;

  final HostLocation? location;

  @JsonKey(name: 'ssh_config')
  final SshConfig sshConfig;

  final HostMetadata metadata;

  final String status;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  @JsonKey(name: 'last_seen')
  final String lastSeen;

  Host({
    this.id,
    required this.hostId,
    required this.hostname,
    required this.ipAddress,
    required this.environment,
    required this.region,
    this.location,
    required this.sshConfig,
    required this.metadata,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeen,
  });

  factory Host.fromJson(Map<String, dynamic> json) => _$HostFromJson(json);

  Map<String, dynamic> toJson() => _$HostToJson(this);
}

@JsonSerializable()
class HostLocation {
  final String? datacenter;
  final String? rack;
  final String? city;
  final String? country;

  HostLocation({
    this.datacenter,
    this.rack,
    this.city,
    this.country,
  });

  factory HostLocation.fromJson(Map<String, dynamic> json) =>
      _$HostLocationFromJson(json);

  Map<String, dynamic> toJson() => _$HostLocationToJson(this);
}

@JsonSerializable()
class SshConfig {
  final String user;
  final int port;

  @JsonKey(name: 'key_path')
  final String? keyPath;

  @JsonKey(name: 'use_sudo')
  final bool useSudo;

  SshConfig({
    required this.user,
    required this.port,
    this.keyPath,
    required this.useSudo,
  });

  factory SshConfig.fromJson(Map<String, dynamic> json) =>
      _$SshConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SshConfigToJson(this);
}

@JsonSerializable()
class HostMetadata {
  final String? os;
  final String? purpose;
  final List<String> tags;

  HostMetadata({
    this.os,
    this.purpose,
    required this.tags,
  });

  factory HostMetadata.fromJson(Map<String, dynamic> json) =>
      _$HostMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$HostMetadataToJson(this);
}

@JsonSerializable()
class HostListResponse {
  final bool success;
  final String message;
  final HostListData data;

  HostListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HostListResponse.fromJson(Map<String, dynamic> json) =>
      _$HostListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HostListResponseToJson(this);
}

@JsonSerializable()
class HostListData {
  final List<Host> hosts;
  final int count;

  HostListData({
    required this.hosts,
    required this.count,
  });

  factory HostListData.fromJson(Map<String, dynamic> json) =>
      _$HostListDataFromJson(json);

  Map<String, dynamic> toJson() => _$HostListDataToJson(this);
}

@JsonSerializable()
class HostResponse {
  final bool success;
  final String message;
  final Host data;

  HostResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory HostResponse.fromJson(Map<String, dynamic> json) =>
      _$HostResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HostResponseToJson(this);
}

@JsonSerializable()
class MetadataListResponse {
  final bool success;
  final String message;
  final List<String> data;

  MetadataListResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory MetadataListResponse.fromJson(Map<String, dynamic> json) =>
      _$MetadataListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MetadataListResponseToJson(this);
}
