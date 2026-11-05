// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_overview_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantRoundDto _$ParticipantRoundDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ParticipantRoundDto',
      json,
      ($checkedConvert) {
        final val = ParticipantRoundDto(
          round: $checkedConvert('round', (v) => (v as num).toInt()),
          group: $checkedConvert('group', (v) => v as String),
          lane: $checkedConvert('lane', (v) => (v as num).toInt()),
          assignmentId: $checkedConvert(
            'assignment_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          state: $checkedConvert(
            'state',
            (v) => $enumDecode(_$ParticipantScoreStateEnumMap, v),
          ),
          isNextToScore: $checkedConvert('is_next_to_score', (v) => v as bool),
          enteredBy: $checkedConvert('entered_by', (v) => v as String?),
          enteredAt: $checkedConvert(
            'entered_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          scoreRevision: $checkedConvert(
            'score_revision',
            (v) => (v as num?)?.toInt() ?? 0,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'assignmentId': 'assignment_id',
        'isNextToScore': 'is_next_to_score',
        'enteredBy': 'entered_by',
        'enteredAt': 'entered_at',
        'scoreRevision': 'score_revision',
      },
    );

Map<String, dynamic> _$ParticipantRoundDtoToJson(
  ParticipantRoundDto instance,
) => <String, dynamic>{
  'round': instance.round,
  'group': instance.group,
  'lane': instance.lane,
  'assignment_id': const IdConverter().toJson(instance.assignmentId),
  'state': _$ParticipantScoreStateEnumMap[instance.state]!,
  'is_next_to_score': instance.isNextToScore,
  'entered_by': instance.enteredBy,
  'entered_at': instance.enteredAt?.toIso8601String(),
  'score_revision': instance.scoreRevision,
};

const _$ParticipantScoreStateEnumMap = {
  ParticipantScoreState.notEntered: 'not_entered',
  ParticipantScoreState.draft: 'draft',
  ParticipantScoreState.submitted: 'submitted',
  ParticipantScoreState.reviewRequested: 'review_requested',
  ParticipantScoreState.underReview: 'under_review',
  ParticipantScoreState.official: 'official',
  ParticipantScoreState.locked: 'locked',
  ParticipantScoreState.zero: 'zero',
  ParticipantScoreState.retired: 'retired',
};

ParticipantOverviewDto _$ParticipantOverviewDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ParticipantOverviewDto', json, ($checkedConvert) {
  final val = ParticipantOverviewDto(
    contest: $checkedConvert(
      'contest',
      (v) => ParticipantContestDto.fromJson(v as Map<String, dynamic>),
    ),
    participant: $checkedConvert(
      'participant',
      (v) => ParticipantLinkDto.fromJson(v as Map<String, dynamic>),
    ),
    matrixRevision: $checkedConvert(
      'matrix_revision',
      (v) => (v as num).toInt(),
    ),
    locked: $checkedConvert('locked', (v) => v as bool),
    rounds: $checkedConvert(
      'rounds',
      (v) => (v as List<dynamic>)
          .map((e) => ParticipantRoundDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'matrixRevision': 'matrix_revision'});

Map<String, dynamic> _$ParticipantOverviewDtoToJson(
  ParticipantOverviewDto instance,
) => <String, dynamic>{
  'contest': instance.contest,
  'participant': instance.participant,
  'matrix_revision': instance.matrixRevision,
  'locked': instance.locked,
  'rounds': instance.rounds,
};
