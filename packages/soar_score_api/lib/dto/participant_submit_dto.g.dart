// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_submit_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubmitParticipantScoreRequest _$SubmitParticipantScoreRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SubmitParticipantScoreRequest',
  json,
  ($checkedConvert) {
    final val = SubmitParticipantScoreRequest(
      clientMutationId: $checkedConvert(
        'client_mutation_id',
        (v) => v as String,
      ),
      matrixRevision: $checkedConvert(
        'matrix_revision',
        (v) => (v as num).toInt(),
      ),
      components: $checkedConvert(
        'components',
        (v) => v as Map<String, dynamic>,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'clientMutationId': 'client_mutation_id',
    'matrixRevision': 'matrix_revision',
  },
);

Map<String, dynamic> _$SubmitParticipantScoreRequestToJson(
  SubmitParticipantScoreRequest instance,
) => <String, dynamic>{
  'client_mutation_id': instance.clientMutationId,
  'matrix_revision': instance.matrixRevision,
  'components': instance.components,
};

ParticipantScoreDto _$ParticipantScoreDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ParticipantScoreDto',
      json,
      ($checkedConvert) {
        final val = ParticipantScoreDto(
          assignmentId: $checkedConvert(
            'assignment_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          round: $checkedConvert('round', (v) => (v as num).toInt()),
          state: $checkedConvert(
            'state',
            (v) => $enumDecode(_$ParticipantScoreStateEnumMap, v),
          ),
          revision: $checkedConvert('revision', (v) => (v as num).toInt()),
          components: $checkedConvert(
            'components',
            (v) => v as Map<String, dynamic>,
          ),
          enteredBy: $checkedConvert('entered_by', (v) => v as String),
          enteredAt: $checkedConvert(
            'entered_at',
            (v) => DateTime.parse(v as String),
          ),
          flightScore: $checkedConvert('flight_score', (v) => v as num?),
          rawScore: $checkedConvert('raw_score', (v) => v as num?),
          roundScore: $checkedConvert('round_score', (v) => v as num?),
          cumulativePenalty: $checkedConvert(
            'cumulative_penalty',
            (v) => v as num?,
          ),
          validationMessages: $checkedConvert(
            'validation_messages',
            (v) =>
                (v as List<dynamic>?)?.map((e) => e as String).toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'assignmentId': 'assignment_id',
        'enteredBy': 'entered_by',
        'enteredAt': 'entered_at',
        'flightScore': 'flight_score',
        'rawScore': 'raw_score',
        'roundScore': 'round_score',
        'cumulativePenalty': 'cumulative_penalty',
        'validationMessages': 'validation_messages',
      },
    );

Map<String, dynamic> _$ParticipantScoreDtoToJson(
  ParticipantScoreDto instance,
) => <String, dynamic>{
  'assignment_id': const IdConverter().toJson(instance.assignmentId),
  'round': instance.round,
  'state': _$ParticipantScoreStateEnumMap[instance.state]!,
  'revision': instance.revision,
  'components': instance.components,
  'entered_by': instance.enteredBy,
  'entered_at': instance.enteredAt.toIso8601String(),
  'flight_score': instance.flightScore,
  'raw_score': instance.rawScore,
  'round_score': instance.roundScore,
  'cumulative_penalty': instance.cumulativePenalty,
  'validation_messages': instance.validationMessages,
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

SubmitParticipantScoreResponse _$SubmitParticipantScoreResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SubmitParticipantScoreResponse',
  json,
  ($checkedConvert) {
    final val = SubmitParticipantScoreResponse(
      score: $checkedConvert(
        'score',
        (v) => ParticipantScoreDto.fromJson(v as Map<String, dynamic>),
      ),
      nextOperation: $checkedConvert('next_operation', (v) => v as String),
      nextRound: $checkedConvert('next_round', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'nextOperation': 'next_operation',
    'nextRound': 'next_round',
  },
);

Map<String, dynamic> _$SubmitParticipantScoreResponseToJson(
  SubmitParticipantScoreResponse instance,
) => <String, dynamic>{
  'score': instance.score,
  'next_operation': instance.nextOperation,
  'next_round': instance.nextRound,
};

FieldErrorDto _$FieldErrorDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FieldErrorDto', json, ($checkedConvert) {
      final val = FieldErrorDto(
        field: $checkedConvert('field', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$FieldErrorDtoToJson(FieldErrorDto instance) =>
    <String, dynamic>{'field': instance.field, 'code': instance.code};

ParticipantErrorDto _$ParticipantErrorDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ParticipantErrorDto',
      json,
      ($checkedConvert) {
        final val = ParticipantErrorDto(
          code: $checkedConvert('code', (v) => v as String),
          message: $checkedConvert('message', (v) => v as String),
          requestId: $checkedConvert('request_id', (v) => v as String?),
          acceptedScore: $checkedConvert(
            'accepted_score',
            (v) => v == null
                ? null
                : ParticipantScoreDto.fromJson(v as Map<String, dynamic>),
          ),
          nextOperation: $checkedConvert('next_operation', (v) => v as String?),
          fieldErrors: $checkedConvert(
            'field_errors',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) => FieldErrorDto.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'requestId': 'request_id',
        'acceptedScore': 'accepted_score',
        'nextOperation': 'next_operation',
        'fieldErrors': 'field_errors',
      },
    );

Map<String, dynamic> _$ParticipantErrorDtoToJson(
  ParticipantErrorDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'request_id': instance.requestId,
  'accepted_score': instance.acceptedScore,
  'next_operation': instance.nextOperation,
  'field_errors': instance.fieldErrors,
};
