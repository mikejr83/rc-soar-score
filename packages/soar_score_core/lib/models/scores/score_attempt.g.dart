// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_attempt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreAttempt _$ScoreAttemptFromJson(Map<String, dynamic> json) => ScoreAttempt(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  scorePlaceholderId: const IdConverter().fromJson(
    json['score_placeholder_id'] as String,
  ),
  configRevisionId: const IdConverter().fromJson(
    json['config_revision_id'] as String,
  ),
  matrixRevisionId: const IdConverter().fromJson(
    json['matrix_revision_id'] as String,
  ),
  rawComponents: json['raw_components'] as Map<String, dynamic>,
  actorId: const IdConverter().fromJson(json['actor_id'] as String),
  authority: $enumDecode(_$AuthorityEnumMap, json['authority']),
  invitationId: _$JsonConverterFromJson<String, Id>(
    json['invitation_id'],
    const IdConverter().fromJson,
  ),
  sourceDevice: json['source_device'] as String?,
  clientMutationId: json['client_mutation_id'] as String,
  baseScoreRevision: (json['base_score_revision'] as num).toInt(),
  acceptedAt: const UtcTimestampConverter().fromJson(
    json['accepted_at'] as String,
  ),
);

Map<String, dynamic> _$ScoreAttemptToJson(
  ScoreAttempt instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'score_placeholder_id': const IdConverter().toJson(
    instance.scorePlaceholderId,
  ),
  'config_revision_id': const IdConverter().toJson(instance.configRevisionId),
  'matrix_revision_id': const IdConverter().toJson(instance.matrixRevisionId),
  'raw_components': instance.rawComponents,
  'actor_id': const IdConverter().toJson(instance.actorId),
  'authority': _$AuthorityEnumMap[instance.authority]!,
  'invitation_id': _$JsonConverterToJson<String, Id>(
    instance.invitationId,
    const IdConverter().toJson,
  ),
  'source_device': instance.sourceDevice,
  'client_mutation_id': instance.clientMutationId,
  'base_score_revision': instance.baseScoreRevision,
  'accepted_at': const UtcTimestampConverter().toJson(instance.acceptedAt),
};

const _$AuthorityEnumMap = {
  Authority.director: 'Director',
  Authority.participant: 'Participant',
  Authority.helper: 'Helper',
  Authority.system: 'System',
  Authority.administrator: 'Administrator',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
