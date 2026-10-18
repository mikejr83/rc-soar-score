// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_publication_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPublicationDto _$PublicPublicationDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicPublicationDto',
  json,
  ($checkedConvert) {
    final val = PublicPublicationDto(
      publicationId: $checkedConvert(
        'publication_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      visibility: $checkedConvert('visibility', (v) => v as String),
      projectionRevision: $checkedConvert(
        'projection_revision',
        (v) => (v as num).toInt(),
      ),
      publishedAt: $checkedConvert(
        'published_at',
        (v) => DateTime.parse(v as String),
      ),
      contest: $checkedConvert('contest', (v) => v as Map<String, dynamic>),
      disciplineType: $checkedConvert('discipline_type', (v) => v as String),
      calculationVersion: $checkedConvert(
        'calculation_version',
        (v) => v as String,
      ),
      resultsHiddenThroughRound: $checkedConvert(
        'results_hidden_through_round',
        (v) => (v as num?)?.toInt(),
      ),
      participants: $checkedConvert(
        'participants',
        (v) => v as List<dynamic>? ?? const [],
      ),
      teams: $checkedConvert('teams', (v) => v as List<dynamic>? ?? const []),
      matrix: $checkedConvert('matrix', (v) => v as Map<String, dynamic>?),
      scores: $checkedConvert('scores', (v) => v as List<dynamic>? ?? const []),
      standings: $checkedConvert(
        'standings',
        (v) => v as Map<String, dynamic>? ?? const {'rounds': <Object?>[]},
      ),
      calculation: $checkedConvert(
        'calculation',
        (v) => v as Map<String, dynamic>?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'publicationId': 'publication_id',
    'projectionRevision': 'projection_revision',
    'publishedAt': 'published_at',
    'disciplineType': 'discipline_type',
    'calculationVersion': 'calculation_version',
    'resultsHiddenThroughRound': 'results_hidden_through_round',
  },
);

Map<String, dynamic> _$PublicPublicationDtoToJson(
  PublicPublicationDto instance,
) => <String, dynamic>{
  'publication_id': const IdConverter().toJson(instance.publicationId),
  'visibility': instance.visibility,
  'projection_revision': instance.projectionRevision,
  'published_at': instance.publishedAt.toIso8601String(),
  'contest': instance.contest,
  'discipline_type': instance.disciplineType,
  'calculation_version': instance.calculationVersion,
  'results_hidden_through_round': instance.resultsHiddenThroughRound,
  'participants': instance.participants,
  'teams': instance.teams,
  'matrix': instance.matrix,
  'scores': instance.scores,
  'standings': instance.standings,
  'calculation': instance.calculation,
};
