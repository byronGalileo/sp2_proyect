// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Host _$HostFromJson(Map<String, dynamic> json) => Host(
  id: json['_id'] as String?,
  hostId: json['host_id'] as String,
  hostname: json['hostname'] as String,
  ipAddress: json['ip_address'] as String,
  environment: json['environment'] as String,
  region: json['region'] as String,
  location: json['location'] == null
      ? null
      : HostLocation.fromJson(json['location'] as Map<String, dynamic>),
  sshConfig: SshConfig.fromJson(json['ssh_config'] as Map<String, dynamic>),
  metadata: HostMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  lastSeen: json['last_seen'] as String,
);

Map<String, dynamic> _$HostToJson(Host instance) => <String, dynamic>{
  '_id': instance.id,
  'host_id': instance.hostId,
  'hostname': instance.hostname,
  'ip_address': instance.ipAddress,
  'environment': instance.environment,
  'region': instance.region,
  'location': instance.location,
  'ssh_config': instance.sshConfig,
  'metadata': instance.metadata,
  'status': instance.status,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'last_seen': instance.lastSeen,
};

HostLocation _$HostLocationFromJson(Map<String, dynamic> json) => HostLocation(
  datacenter: json['datacenter'] as String?,
  rack: json['rack'] as String?,
  city: json['city'] as String?,
  country: json['country'] as String?,
);

Map<String, dynamic> _$HostLocationToJson(HostLocation instance) =>
    <String, dynamic>{
      'datacenter': instance.datacenter,
      'rack': instance.rack,
      'city': instance.city,
      'country': instance.country,
    };

SshConfig _$SshConfigFromJson(Map<String, dynamic> json) => SshConfig(
  user: json['user'] as String,
  port: (json['port'] as num).toInt(),
  keyPath: json['key_path'] as String?,
  useSudo: json['use_sudo'] as bool,
);

Map<String, dynamic> _$SshConfigToJson(SshConfig instance) => <String, dynamic>{
  'user': instance.user,
  'port': instance.port,
  'key_path': instance.keyPath,
  'use_sudo': instance.useSudo,
};

HostMetadata _$HostMetadataFromJson(Map<String, dynamic> json) => HostMetadata(
  os: json['os'] as String?,
  purpose: json['purpose'] as String?,
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  configPath: json['config_path'] as String?,
  configGeneratedAt: json['config_generated_at'] as String?,
  configServicesCount: (json['config_services_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$HostMetadataToJson(HostMetadata instance) =>
    <String, dynamic>{
      'os': instance.os,
      'purpose': instance.purpose,
      'tags': instance.tags,
      'config_path': instance.configPath,
      'config_generated_at': instance.configGeneratedAt,
      'config_services_count': instance.configServicesCount,
    };

HostListResponse _$HostListResponseFromJson(Map<String, dynamic> json) =>
    HostListResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: HostListData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HostListResponseToJson(HostListResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

HostListData _$HostListDataFromJson(Map<String, dynamic> json) => HostListData(
  hosts: (json['hosts'] as List<dynamic>)
      .map((e) => Host.fromJson(e as Map<String, dynamic>))
      .toList(),
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$HostListDataToJson(HostListData instance) =>
    <String, dynamic>{'hosts': instance.hosts, 'count': instance.count};

HostResponse _$HostResponseFromJson(Map<String, dynamic> json) => HostResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: Host.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$HostResponseToJson(HostResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

MetadataListResponse _$MetadataListResponseFromJson(
  Map<String, dynamic> json,
) => MetadataListResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: MetadataListData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MetadataListResponseToJson(
  MetadataListResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

MetadataListData _$MetadataListDataFromJson(Map<String, dynamic> json) =>
    MetadataListData(
      environments: (json['environments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      regions: (json['regions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MetadataListDataToJson(MetadataListData instance) =>
    <String, dynamic>{
      'environments': instance.environments,
      'regions': instance.regions,
    };
