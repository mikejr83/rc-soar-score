// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreFieldDto _$ScoreFieldDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScoreFieldDto', json, ($checkedConvert) {
      final val = ScoreFieldDto(
        key: $checkedConvert('key', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        required: $checkedConvert('required', (v) => v as bool),
        unit: $checkedConvert('unit', (v) => v as String?),
        precision: $checkedConvert('precision', (v) => (v as num?)?.toInt()),
        min: $checkedConvert('min', (v) => v as num?),
        max: $checkedConvert('max', (v) => v as num?),
        options: $checkedConvert(
          'options',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) =>
                        ScoreFieldOptionDto.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              const [],
        ),
        dependsOn: $checkedConvert(
          'depends_on',
          (v) => v as Map<String, dynamic>? ?? const {},
        ),
      );
      return val;
    }, fieldKeyMap: const {'dependsOn': 'depends_on'});

Map<String, dynamic> _$ScoreFieldDtoToJson(ScoreFieldDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'type': instance.type,
      'required': instance.required,
      'unit': instance.unit,
      'precision': instance.precision,
      'min': instance.min,
      'max': instance.max,
      'options': instance.options,
      'depends_on': instance.dependsOn,
    };

ScoreFieldOptionDto _$ScoreFieldOptionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ScoreFieldOptionDto', json, ($checkedConvert) {
      final val = ScoreFieldOptionDto(
        value: $checkedConvert('value', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ScoreFieldOptionDtoToJson(
  ScoreFieldOptionDto instance,
) => <String, dynamic>{'value': instance.value, 'label': instance.label};

LandingOptionDto _$LandingOptionDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LandingOptionDto', json, ($checkedConvert) {
      final val = LandingOptionDto(
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        points: $checkedConvert('points', (v) => (v as num).toInt()),
        description: $checkedConvert('description', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LandingOptionDtoToJson(LandingOptionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'points': instance.points,
      'description': instance.description,
    };

ParticipantEntryContextDto _$ParticipantEntryContextDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ParticipantEntryContextDto',
  json,
  ($checkedConvert) {
    final val = ParticipantEntryContextDto(
      assignmentId: $checkedConvert(
        'assignment_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      round: $checkedConvert('round', (v) => (v as num).toInt()),
      roundCount: $checkedConvert('round_count', (v) => (v as num).toInt()),
      lastOpenRound: $checkedConvert(
        'last_open_round',
        (v) => (v as num?)?.toInt(),
      ),
      group: $checkedConvert('group', (v) => v as String),
      lane: $checkedConvert('lane', (v) => (v as num?)?.toInt()),
      taskType: $checkedConvert('task_type', (v) => v as String?),
      matrixRevision: $checkedConvert(
        'matrix_revision',
        (v) => (v as num).toInt(),
      ),
      scoreRevision: $checkedConvert(
        'score_revision',
        (v) => (v as num).toInt(),
      ),
      rulesVersion: $checkedConvert('rules_version', (v) => v as String),
      state: $checkedConvert(
        'state',
        (v) => $enumDecode(_$ParticipantScoreStateEnumMap, v),
      ),
      fields: $checkedConvert(
        'fields',
        (v) => (v as List<dynamic>)
            .map((e) => ScoreFieldDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      landingTable: $checkedConvert(
        'landing_table',
        (v) => (v as List<dynamic>)
            .map((e) => LandingOptionDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      allowsMotorRestart: $checkedConvert(
        'allows_motor_restart',
        (v) => v as bool? ?? true,
      ),
      submittedScore: $checkedConvert(
        'submitted_score',
        (v) => v == null
            ? null
            : ParticipantScoreDto.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'assignmentId': 'assignment_id',
    'roundCount': 'round_count',
    'lastOpenRound': 'last_open_round',
    'taskType': 'task_type',
    'matrixRevision': 'matrix_revision',
    'scoreRevision': 'score_revision',
    'rulesVersion': 'rules_version',
    'landingTable': 'landing_table',
    'allowsMotorRestart': 'allows_motor_restart',
    'submittedScore': 'submitted_score',
  },
);

Map<String, dynamic> _$ParticipantEntryContextDtoToJson(
  ParticipantEntryContextDto instance,
) => <String, dynamic>{
  'assignment_id': const IdConverter().toJson(instance.assignmentId),
  'round': instance.round,
  'round_count': instance.roundCount,
  'last_open_round': instance.lastOpenRound,
  'group': instance.group,
  'lane': instance.lane,
  'task_type': instance.taskType,
  'matrix_revision': instance.matrixRevision,
  'score_revision': instance.scoreRevision,
  'rules_version': instance.rulesVersion,
  'state': _$ParticipantScoreStateEnumMap[instance.state]!,
  'fields': instance.fields,
  'landing_table': instance.landingTable,
  'allows_motor_restart': instance.allowsMotorRestart,
  'submitted_score': instance.submittedScore,
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
