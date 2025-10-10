import 'package:json_annotation/json_annotation.dart';

part 'permission.g.dart';

@JsonSerializable()
class Permission {
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(name: 'display_name', defaultValue: '')
  final String displayName;
  final String? description;
  final String? resource;
  final String? action;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Permission({
    required this.id,
    this.name = '',
    this.displayName = '',
    this.description,
    this.resource,
    this.action,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) =>
      _$PermissionFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionToJson(this);
}
