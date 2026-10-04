// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_projection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationProjection _$PublicationProjectionFromJson(
  Map<String, dynamic> json,
) => PublicationProjection(
  id: const IdConverter().fromJson(json['id'] as String),
  publicationId: const IdConverter().fromJson(json['publication_id'] as String),
  projectionRevision: (json['projection_revision'] as num).toInt(),
  contestRevision: (json['contest_revision'] as num).toInt(),
  configRevision: (json['config_revision'] as num).toInt(),
  matrixRevision: (json['matrix_revision'] as num).toInt(),
  disciplineType: $enumDecode(_$DisciplineTypeEnumMap, json['discipline_type']),
  disciplineRulesVersion: (json['discipline_rules_version'] as num).toInt(),
  calculationVersion: json['calculation_version'] as String,
  contestIdentity: json['contest_identity'] as Map<String, dynamic>,
  participants: json['participants'] as List<dynamic>?,
  teams: json['teams'] as List<dynamic>?,
  matrixInfo: json['matrix_info'] as Map<String, dynamic>?,
  scores: json['scores'] as List<dynamic>?,
  standings: json['standings'] as Map<String, dynamic>?,
  calculationMetadata: json['calculation_metadata'] as Map<String, dynamic>?,
  publishedAt: const UtcTimestampConverter().fromJson(
    json['published_at'] as String,
  ),
  publishedBy: _$JsonConverterFromJson<String, Id>(
    json['published_by'],
    const IdConverter().fromJson,
  ),
  clientMutationId: json['client_mutation_id'] as String,
);

Map<String, dynamic> _$PublicationProjectionToJson(
  PublicationProjection instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'publication_id': const IdConverter().toJson(instance.publicationId),
  'projection_revision': instance.projectionRevision,
  'contest_revision': instance.contestRevision,
  'config_revision': instance.configRevision,
  'matrix_revision': instance.matrixRevision,
  'discipline_type': _$DisciplineTypeEnumMap[instance.disciplineType]!,
  'discipline_rules_version': instance.disciplineRulesVersion,
  'calculation_version': instance.calculationVersion,
  'contest_identity': instance.contestIdentity,
  'participants': instance.participants,
  'teams': instance.teams,
  'matrix_info': instance.matrixInfo,
  'scores': instance.scores,
  'standings': instance.standings,
  'calculation_metadata': instance.calculationMetadata,
  'published_at': const UtcTimestampConverter().toJson(instance.publishedAt),
  'published_by': _$JsonConverterToJson<String, Id>(
    instance.publishedBy,
    const IdConverter().toJson,
  ),
  'client_mutation_id': instance.clientMutationId,
};

const _$DisciplineTypeEnumMap = {
  DisciplineType.ales: 'ALES',
  DisciplineType.thermalDuration: 'ThermalDuration',
  DisciplineType.f3j: 'F3J',
  DisciplineType.f5j: 'F5J',
  DisciplineType.f3l: 'F3L',
  DisciplineType.f3k: 'F3K',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
