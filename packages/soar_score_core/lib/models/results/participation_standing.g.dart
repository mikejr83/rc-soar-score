// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participation_standing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipationStanding _$ParticipationStandingFromJson(
  Map<String, dynamic> json,
) => ParticipationStanding(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  contestParticipationId: const IdConverter().fromJson(
    json['contest_participation_id'] as String,
  ),
  asOfRound: (json['as_of_round'] as num).toInt(),
  place: (json['place'] as num).toInt(),
  isTied: json['is_tied'] as bool? ?? false,
  rawTotal: (json['raw_total'] as num).toDouble(),
  droppedRounds:
      (json['dropped_rounds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  penaltyTotal: (json['penalty_total'] as num?)?.toDouble() ?? 0,
  overallScore: (json['overall_score'] as num).toDouble(),
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

Map<String, dynamic> _$ParticipationStandingToJson(
  ParticipationStanding instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'contest_participation_id': const IdConverter().toJson(
    instance.contestParticipationId,
  ),
  'as_of_round': instance.asOfRound,
  'place': instance.place,
  'is_tied': instance.isTied,
  'raw_total': instance.rawTotal,
  'dropped_rounds': instance.droppedRounds,
  'penalty_total': instance.penaltyTotal,
  'overall_score': instance.overallScore,
  'is_preliminary': instance.isPreliminary,
  'config_revision_id': const IdConverter().toJson(instance.configRevisionId),
  'matrix_revision_id': const IdConverter().toJson(instance.matrixRevisionId),
  'calculation_version': instance.calculationVersion,
  'computed_at': const UtcTimestampConverter().toJson(instance.computedAt),
};
