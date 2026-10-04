// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_standing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamStanding _$TeamStandingFromJson(Map<String, dynamic> json) => TeamStanding(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  teamId: const IdConverter().fromJson(json['team_id'] as String),
  asOfRound: (json['as_of_round'] as num).toInt(),
  place: (json['place'] as num).toInt(),
  isTied: json['is_tied'] as bool? ?? false,
  teamScore: (json['team_score'] as num).toDouble(),
  countedParticipations:
      (json['counted_participations'] as List<dynamic>?)
          ?.map((e) => const IdConverter().fromJson(e as String))
          .toList() ??
      const [],
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

Map<String, dynamic> _$TeamStandingToJson(
  TeamStanding instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'team_id': const IdConverter().toJson(instance.teamId),
  'as_of_round': instance.asOfRound,
  'place': instance.place,
  'is_tied': instance.isTied,
  'team_score': instance.teamScore,
  'counted_participations': instance.countedParticipations
      .map(const IdConverter().toJson)
      .toList(),
  'is_preliminary': instance.isPreliminary,
  'config_revision_id': const IdConverter().toJson(instance.configRevisionId),
  'matrix_revision_id': const IdConverter().toJson(instance.matrixRevisionId),
  'calculation_version': instance.calculationVersion,
  'computed_at': const UtcTimestampConverter().toJson(instance.computedAt),
};
