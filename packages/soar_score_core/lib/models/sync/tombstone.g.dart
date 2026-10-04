// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tombstone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tombstone _$TombstoneFromJson(Map<String, dynamic> json) => Tombstone(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: _$JsonConverterFromJson<String, Id>(
    json['contest_id'],
    const IdConverter().fromJson,
  ),
  ownerAccountId: _$JsonConverterFromJson<String, Id>(
    json['owner_account_id'],
    const IdConverter().fromJson,
  ),
  entityType: json['entity_type'] as String,
  entityId: const IdConverter().fromJson(json['entity_id'] as String),
  status:
      $enumDecodeNullable(_$TombstoneStatusEnumMap, json['status']) ??
      TombstoneStatus.pending,
  deletedAt: const UtcTimestampConverter().fromJson(
    json['deleted_at'] as String,
  ),
  acknowledgedAt: _$JsonConverterFromJson<String, DateTime>(
    json['acknowledged_at'],
    const UtcTimestampConverter().fromJson,
  ),
  purgeAfter: _$JsonConverterFromJson<String, DateTime>(
    json['purge_after'],
    const UtcTimestampConverter().fromJson,
  ),
  deletionReason: json['deletion_reason'] as String?,
);

Map<String, dynamic> _$TombstoneToJson(Tombstone instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': _$JsonConverterToJson<String, Id>(
    instance.contestId,
    const IdConverter().toJson,
  ),
  'owner_account_id': _$JsonConverterToJson<String, Id>(
    instance.ownerAccountId,
    const IdConverter().toJson,
  ),
  'entity_type': instance.entityType,
  'entity_id': const IdConverter().toJson(instance.entityId),
  'status': _$TombstoneStatusEnumMap[instance.status]!,
  'deleted_at': const UtcTimestampConverter().toJson(instance.deletedAt),
  'acknowledged_at': _$JsonConverterToJson<String, DateTime>(
    instance.acknowledgedAt,
    const UtcTimestampConverter().toJson,
  ),
  'purge_after': _$JsonConverterToJson<String, DateTime>(
    instance.purgeAfter,
    const UtcTimestampConverter().toJson,
  ),
  'deletion_reason': instance.deletionReason,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$TombstoneStatusEnumMap = {
  TombstoneStatus.pending: 'Pending',
  TombstoneStatus.acknowledged: 'Acknowledged',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
