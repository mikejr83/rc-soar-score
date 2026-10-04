// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Role _$RoleFromJson(Map<String, dynamic> json) => Role(
  id: const IdConverter().fromJson(json['id'] as String),
  ownerAccountId: _$JsonConverterFromJson<String, Id>(
    json['owner_account_id'],
    const IdConverter().fromJson,
  ),
  displayName: json['display_name'] as String,
  type: $enumDecode(_$RoleTypeEnumMap, json['type']),
  archivedAt: _$JsonConverterFromJson<String, DateTime>(
    json['archived_at'],
    const UtcTimestampConverter().fromJson,
  ),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RoleToJson(Role instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'owner_account_id': _$JsonConverterToJson<String, Id>(
    instance.ownerAccountId,
    const IdConverter().toJson,
  ),
  'display_name': instance.displayName,
  'type': _$RoleTypeEnumMap[instance.type]!,
  'archived_at': _$JsonConverterToJson<String, DateTime>(
    instance.archivedAt,
    const UtcTimestampConverter().toJson,
  ),
  'revision': instance.revision,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$RoleTypeEnumMap = {
  RoleType.pilot: 'Pilot',
  RoleType.nonFlier: 'NonFlier',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
