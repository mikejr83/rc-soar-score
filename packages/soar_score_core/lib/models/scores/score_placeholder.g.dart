// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_placeholder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScorePlaceholder _$ScorePlaceholderFromJson(Map<String, dynamic> json) =>
    ScorePlaceholder(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      contestParticipationId: const IdConverter().fromJson(
        json['contest_participation_id'] as String,
      ),
      assignmentId: const IdConverter().fromJson(
        json['assignment_id'] as String,
      ),
      state:
          $enumDecodeNullable(_$ScorePlaceholderStateEnumMap, json['state']) ??
          ScorePlaceholderState.notEntered,
      scoreRevision: (json['score_revision'] as num?)?.toInt() ?? 0,
      currentAttemptId: _$JsonConverterFromJson<String, Id>(
        json['current_attempt_id'],
        const IdConverter().fromJson,
      ),
      lockedBy: _$JsonConverterFromJson<String, Id>(
        json['locked_by'],
        const IdConverter().fromJson,
      ),
      lockedAt: _$JsonConverterFromJson<String, DateTime>(
        json['locked_at'],
        const UtcTimestampConverter().fromJson,
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ScorePlaceholderToJson(ScorePlaceholder instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'contest_participation_id': const IdConverter().toJson(
        instance.contestParticipationId,
      ),
      'assignment_id': const IdConverter().toJson(instance.assignmentId),
      'state': _$ScorePlaceholderStateEnumMap[instance.state]!,
      'score_revision': instance.scoreRevision,
      'current_attempt_id': _$JsonConverterToJson<String, Id>(
        instance.currentAttemptId,
        const IdConverter().toJson,
      ),
      'locked_by': _$JsonConverterToJson<String, Id>(
        instance.lockedBy,
        const IdConverter().toJson,
      ),
      'locked_at': _$JsonConverterToJson<String, DateTime>(
        instance.lockedAt,
        const UtcTimestampConverter().toJson,
      ),
      'revision': instance.revision,
    };

const _$ScorePlaceholderStateEnumMap = {
  ScorePlaceholderState.notEntered: 'NotEntered',
  ScorePlaceholderState.submitted: 'Submitted',
  ScorePlaceholderState.inReview: 'InReview',
  ScorePlaceholderState.official: 'Official',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
