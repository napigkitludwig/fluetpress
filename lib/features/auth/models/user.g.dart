// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num?)?.toInt(),
  username: json['username'] as String,
  password: json['password'] as String? ?? '',
  role: const UserRoleConverter().fromJson(json['role'] as String),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': ?instance.id,
  'username': instance.username,
  'password': instance.password,
  'role': const UserRoleConverter().toJson(instance.role),
};
