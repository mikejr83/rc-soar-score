// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlightResult _$FlightResultFromJson(Map<String, dynamic> json) => FlightResult(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  scorePlaceholderId: const IdConverter().fromJson(
    json['score_placeholder_id'] as String,
  ),
  officialScoreId: const IdConverter().fromJson(
    json['official_score_id'] as String,
  ),
  contestParticipationId: const IdConverter().fromJson(
    json['contest_participation_id'] as String,
  ),
  creditedRoundId: const IdConverter().fromJson(
    json['credited_round_id'] as String,
  ),
  outcome: $enumDecode(_$FlightOutcomeEnumMap, json['outcome']),
  rawPoints: (json['raw_points'] as num).toDouble(),
  landingPoints: (json['landing_points'] as num?)?.toDouble(),
  flightPenaltyPoints: (json['flight_penalty_points'] as num?)?.toDouble(),
  cumulativePenalty: (json['cumulative_penalty'] as num?)?.toInt(),
  groupScore: (json['group_score'] as num).toDouble(),
  isSelected: json['is_selected'] as bool? ?? true,
  isPreliminary: json['is_preliminary'] as bool,
  configRevisionId: const IdConverter().fromJson(
    json['config_revision_id'] as String,
  ),
  matrixRevisionId: const IdConverter().fromJson(
    json['matrix_revision_id'] as String,
  ),
  calculationVersion: json['calculation_version'] as String,
  computedAt: const UtcTimestampConverter().fromJson(
    json['computed_at'] as String,
  ),
);

Map<String, dynamic> _$FlightResultToJson(
  FlightResult instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'score_placeholder_id': const IdConverter().toJson(
    instance.scorePlaceholderId,
  ),
  'official_score_id': const IdConverter().toJson(instance.officialScoreId),
  'contest_participation_id': const IdConverter().toJson(
    instance.contestParticipationId,
  ),
  'credited_round_id': const IdConverter().toJson(instance.creditedRoundId),
  'outcome': _$FlightOutcomeEnumMap[instance.outcome]!,
  'raw_points': instance.rawPoints,
  'landing_points': instance.landingPoints,
  'flight_penalty_points': instance.flightPenaltyPoints,
  'cumulative_penalty': instance.cumulativePenalty,
  'group_score': instance.groupScore,
  'is_selected': instance.isSelected,
  'is_preliminary': instance.isPreliminary,
  'config_revision_id': const IdConverter().toJson(instance.configRevisionId),
  'matrix_revision_id': const IdConverter().toJson(instance.matrixRevisionId),
  'calculation_version': instance.calculationVersion,
  'computed_at': const UtcTimestampConverter().toJson(instance.computedAt),
};

const _$FlightOutcomeEnumMap = {
  FlightOutcome.scored: 'Scored',
  FlightOutcome.zero: 'Zero',
};
