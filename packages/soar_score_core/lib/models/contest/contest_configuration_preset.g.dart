// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_configuration_preset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestConfigurationPreset _$ContestConfigurationPresetFromJson(
  Map<String, dynamic> json,
) => ContestConfigurationPreset(
  id: const IdConverter().fromJson(json['id'] as String),
  ownerAccountId: const IdConverter().fromJson(
    json['owner_account_id'] as String,
  ),
  disciplineProfileId: const IdConverter().fromJson(
    json['discipline_profile_id'] as String,
  ),
  name: json['name'] as String,
  description: json['description'] as String?,
  config: _configFromJson(json['config'] as Map<String, Object?>),
  landingTableId: _$JsonConverterFromJson<String, Id>(
    json['landing_table_id'],
    const IdConverter().fromJson,
  ),
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  updatedAt: const UtcTimestampConverter().fromJson(
    json['updated_at'] as String,
  ),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ContestConfigurationPresetToJson(
  ContestConfigurationPreset instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'owner_account_id': const IdConverter().toJson(instance.ownerAccountId),
  'discipline_profile_id': const IdConverter().toJson(
    instance.disciplineProfileId,
  ),
  'name': instance.name,
  'description': instance.description,
  'config': _configToJson(instance.config),
  'landing_table_id': _$JsonConverterToJson<String, Id>(
    instance.landingTableId,
    const IdConverter().toJson,
  ),
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
  'revision': instance.revision,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
