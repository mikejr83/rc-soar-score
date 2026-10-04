// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_configuration_revision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestConfigurationRevision _$ContestConfigurationRevisionFromJson(
  Map<String, dynamic> json,
) => ContestConfigurationRevision(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  revisionNumber: (json['revision_number'] as num).toInt(),
  disciplineProfileId: const IdConverter().fromJson(
    json['discipline_profile_id'] as String,
  ),
  sourcePresetId: _$JsonConverterFromJson<String, Id>(
    json['source_preset_id'],
    const IdConverter().fromJson,
  ),
  config: _configFromJson(json['config'] as Map<String, Object?>),
  landingTableId: _$JsonConverterFromJson<String, Id>(
    json['landing_table_id'],
    const IdConverter().fromJson,
  ),
  createdBy: const IdConverter().fromJson(json['created_by'] as String),
  notes: json['notes'] as String?,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$ContestConfigurationRevisionToJson(
  ContestConfigurationRevision instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'revision_number': instance.revisionNumber,
  'discipline_profile_id': const IdConverter().toJson(
    instance.disciplineProfileId,
  ),
  'source_preset_id': _$JsonConverterToJson<String, Id>(
    instance.sourcePresetId,
    const IdConverter().toJson,
  ),
  'config': _configToJson(instance.config),
  'landing_table_id': _$JsonConverterToJson<String, Id>(
    instance.landingTableId,
    const IdConverter().toJson,
  ),
  'created_by': const IdConverter().toJson(instance.createdBy),
  'notes': instance.notes,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
