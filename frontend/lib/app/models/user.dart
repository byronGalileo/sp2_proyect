import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? phone;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'email_verified')
  final bool emailVerified;
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(defaultValue: [])
  final List<String> roles;
  @JsonKey(defaultValue: [])
  final List<String> permissions;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.emailVerified,
    this.lastLoginAt,
    required this.createdAt,
    this.roles = const [],
    this.permissions = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? username;
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }
}