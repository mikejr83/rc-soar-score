// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_cursor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncCursor _$SyncCursorFromJson(Map<String, dynamic> json) => SyncCursor(
  id: const IdConverter().fromJson(json['id'] as String),
  installationId: const IdConverter().fromJson(
    json['installation_id'] as String,
  ),
  contestId: _$JsonConverterFromJson<String, Id>(
    json['contest_id'],
    const IdConverter().fromJson,
  ),
  ownerAccountId: _$JsonConverterFromJson<String, Id>(
    json['owner_account_id'],
    const IdConverter().fromJson,
  ),
  lastSyncedSequence: (json['last_synced_sequence'] as num?)?.toInt() ?? 0,
  lastSyncedAt: _$JsonConverterFromJson<String, DateTime>(
    json['last_synced_at'],
    const UtcTimestampConverter().fromJson,
  ),
  updatedAt: const UtcTimestampConverter().fromJson(
    json['updated_at'] as String,
  ),
);

Map<String, dynamic> _$SyncCursorToJson(SyncCursor instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'installation_id': const IdConverter().toJson(instance.installationId),
      'contest_id': _$JsonConverterToJson<String, Id>(
        instance.contestId,
        const IdConverter().toJson,
      ),
      'owner_account_id': _$JsonConverterToJson<String, Id>(
        instance.ownerAccountId,
        const IdConverter().toJson,
      ),
      'last_synced_sequence': instance.lastSyncedSequence,
      'last_synced_at': _$JsonConverterToJson<String, DateTime>(
        instance.lastSyncedAt,
        const UtcTimestampConverter().toJson,
      ),
      'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
