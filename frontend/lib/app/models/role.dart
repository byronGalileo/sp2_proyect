import 'package:json_annotation/json_annotation.dart';
import 'permission.dart';

part 'role.g.dart';

@JsonSerializable()
class Role {
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(name: 'display_name', defaultValue: '')
  final String displayName;
  final String? description;
  @JsonKey(name: 'is_system_role', defaultValue: false)
  final bool isSystemRole;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(defaultValue: [])
  final List<Permission> permissions;

  Role({
    required this.id,
    this.name = '',
    this.displayName = '',
    this.description,
    this.isSystemRole = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.permissions = const [],
  });

  factory Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);

  Map<String, dynamic> toJson() => _$RoleToJson(this);
}
