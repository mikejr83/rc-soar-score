// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatrixAssignment _$MatrixAssignmentFromJson(Map<String, dynamic> json) =>
    MatrixAssignment(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      matrixRevisionId: const IdConverter().fromJson(
        json['matrix_revision_id'] as String,
      ),
      contestParticipationId: const IdConverter().fromJson(
        json['contest_participation_id'] as String,
      ),
      scheduledRoundId: const IdConverter().fromJson(
        json['scheduled_round_id'] as String,
      ),
      creditedRoundId: const IdConverter().fromJson(
        json['credited_round_id'] as String,
      ),
      group: (json['group'] as num).toInt(),
      lane: (json['lane'] as num?)?.toInt(),
      flightSequence: (json['flight_sequence'] as num?)?.toInt() ?? 1,
      assignmentType: $enumDecode(
        _$AssignmentTypeEnumMap,
        json['assignment_type'],
      ),
      sourceAssignmentId: _$JsonConverterFromJson<String, Id>(
        json['source_assignment_id'],
        const IdConverter().fromJson,
      ),
      reFlightId: _$JsonConverterFromJson<String, Id>(
        json['re_flight_id'],
        const IdConverter().fromJson,
      ),
      supersededByAssignmentId: _$JsonConverterFromJson<String, Id>(
        json['superseded_by_assignment_id'],
        const IdConverter().fromJson,
      ),
      actorId: const IdConverter().fromJson(json['actor_id'] as String),
      reason: json['reason'] as String?,
      existingScoreHandling:
          $enumDecodeNullable(
            _$ExistingScoreHandlingEnumMap,
            json['existing_score_handling'],
          ) ??
          ExistingScoreHandling.none,
      resetScoreRevision: (json['reset_score_revision'] as num?)?.toInt(),
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
    );

Map<String, dynamic> _$MatrixAssignmentToJson(
  MatrixAssignment instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'matrix_revision_id': const IdConverter().toJson(instance.matrixRevisionId),
  'contest_participation_id': const IdConverter().toJson(
    instance.contestParticipationId,
  ),
  'scheduled_round_id': const IdConverter().toJson(instance.scheduledRoundId),
  'credited_round_id': const IdConverter().toJson(instance.creditedRoundId),
  'group': instance.group,
  'lane': instance.lane,
  'flight_sequence': instance.flightSequence,
  'assignment_type': _$AssignmentTypeEnumMap[instance.assignmentType]!,
  'source_assignment_id': _$JsonConverterToJson<String, Id>(
    instance.sourceAssignmentId,
    const IdConverter().toJson,
  ),
  're_flight_id': _$JsonConverterToJson<String, Id>(
    instance.reFlightId,
    const IdConverter().toJson,
  ),
  'superseded_by_assignment_id': _$JsonConverterToJson<String, Id>(
    instance.supersededByAssignmentId,
    const IdConverter().toJson,
  ),
  'actor_id': const IdConverter().toJson(instance.actorId),
  'reason': instance.reason,
  'existing_score_handling':
      _$ExistingScoreHandlingEnumMap[instance.existingScoreHandling]!,
  'reset_score_revision': instance.resetScoreRevision,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
};

const _$AssignmentTypeEnumMap = {
  AssignmentType.original: 'Original',
  AssignmentType.moved: 'Moved',
  AssignmentType.reflight: 'Reflight',
  AssignmentType.lateAdd: 'LateAdd',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ExistingScoreHandlingEnumMap = {
  ExistingScoreHandling.none: 'None',
  ExistingScoreHandling.reset: 'Reset',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
