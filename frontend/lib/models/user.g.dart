// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  phone: json['phone'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  isActive: json['is_active'] as bool,
  emailVerified: json['email_verified'] as bool,
  lastLoginAt: json['last_login_at'] == null
      ? null
      : DateTime.parse(json['last_login_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
  permissions: (json['permissions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'phone': instance.phone,
  'avatar_url': instance.avatarUrl,
  'is_active': instance.isActive,
  'email_verified': instance.emailVerified,
  'last_login_at': instance.lastLoginAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'roles': instance.roles,
  'permissions': instance.permissions,
};
