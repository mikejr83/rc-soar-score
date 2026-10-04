// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: const IdConverter().fromJson(json['id'] as String),
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  email: json['email'] as String?,
  emailVerified: json['email_verified'] as bool? ?? false,
  kind: $enumDecode(_$AccountKindEnumMap, json['kind']),
  status:
      $enumDecodeNullable(_$AccountStatusEnumMap, json['status']) ??
      AccountStatus.active,
  archivedAt: _$JsonConverterFromJson<String, DateTime>(
    json['archived_at'],
    const UtcTimestampConverter().fromJson,
  ),
  isSystemAdmin: json['is_system_admin'] as bool? ?? false,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  updatedAt: const UtcTimestampConverter().fromJson(
    json['updated_at'] as String,
  ),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'email': instance.email,
  'email_verified': instance.emailVerified,
  'kind': _$AccountKindEnumMap[instance.kind]!,
  'status': _$AccountStatusEnumMap[instance.status]!,
  'archived_at': _$JsonConverterToJson<String, DateTime>(
    instance.archivedAt,
    const UtcTimestampConverter().toJson,
  ),
  'is_system_admin': instance.isSystemAdmin,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
};

const _$AccountKindEnumMap = {
  AccountKind.registered: 'registered',
  AccountKind.guest: 'guest',
  AccountKind.local: 'local',
  AccountKind.deleted: 'deleted',
};

const _$AccountStatusEnumMap = {
  AccountStatus.active: 'active',
  AccountStatus.archived: 'archived',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
