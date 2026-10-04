// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Installation _$InstallationFromJson(Map<String, dynamic> json) => Installation(
  id: const IdConverter().fromJson(json['id'] as String),
  ownerAccountId: const IdConverter().fromJson(
    json['owner_account_id'] as String,
  ),
  label: json['label'] as String,
  platform: $enumDecode(_$PlatformEnumMap, json['platform']),
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  lastSeenAt: _$JsonConverterFromJson<String, DateTime>(
    json['last_seen_at'],
    const UtcTimestampConverter().fromJson,
  ),
  lastSyncAt: _$JsonConverterFromJson<String, DateTime>(
    json['last_sync_at'],
    const UtcTimestampConverter().fromJson,
  ),
  systemDataSeq: (json['system_data_seq'] as num?)?.toInt() ?? 0,
  revokedAt: _$JsonConverterFromJson<String, DateTime>(
    json['revoked_at'],
    const UtcTimestampConverter().fromJson,
  ),
);

Map<String, dynamic> _$InstallationToJson(Installation instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'owner_account_id': const IdConverter().toJson(instance.ownerAccountId),
      'label': instance.label,
      'platform': _$PlatformEnumMap[instance.platform]!,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
      'last_seen_at': _$JsonConverterToJson<String, DateTime>(
        instance.lastSeenAt,
        const UtcTimestampConverter().toJson,
      ),
      'last_sync_at': _$JsonConverterToJson<String, DateTime>(
        instance.lastSyncAt,
        const UtcTimestampConverter().toJson,
      ),
      'system_data_seq': instance.systemDataSeq,
      'revoked_at': _$JsonConverterToJson<String, DateTime>(
        instance.revokedAt,
        const UtcTimestampConverter().toJson,
      ),
    };

const _$PlatformEnumMap = {
  Platform.web: 'Web',
  Platform.windows: 'Windows',
  Platform.other: 'Other',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
