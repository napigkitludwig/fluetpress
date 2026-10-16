// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  user: const UserJsonConverter().fromJson(
    json['user'] as Map<String, dynamic>,
  ),
  accessToken: json['accessToken'] as String?,
  refreshToken: json['refreshToken'] as String?,
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{
      'user': const UserJsonConverter().toJson(instance.user),
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };
