// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewRequest _$ReviewRequestFromJson(Map<String, dynamic> json) =>
    ReviewRequest(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      scorePlaceholderId: const IdConverter().fromJson(
        json['score_placeholder_id'] as String,
      ),
      proposedComponents: json['proposed_components'] as Map<String, dynamic>,
      participantMessage: json['participant_message'] as String?,
      requesterId: const IdConverter().fromJson(json['requester_id'] as String),
      baseScoreRevision: (json['base_score_revision'] as num).toInt(),
      requestedAt: const UtcTimestampConverter().fromJson(
        json['requested_at'] as String,
      ),
      state:
          $enumDecodeNullable(_$ReviewRequestStateEnumMap, json['state']) ??
          ReviewRequestState.submitted,
      decisionActorId: _$JsonConverterFromJson<String, Id>(
        json['decision_actor_id'],
        const IdConverter().fromJson,
      ),
      decisionTime: _$JsonConverterFromJson<String, DateTime>(
        json['decision_time'],
        const UtcTimestampConverter().fromJson,
      ),
      decisionMessage: json['decision_message'] as String?,
      resultingAttemptId: _$JsonConverterFromJson<String, Id>(
        json['resulting_attempt_id'],
        const IdConverter().fromJson,
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReviewRequestToJson(
  ReviewRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'score_placeholder_id': const IdConverter().toJson(
    instance.scorePlaceholderId,
  ),
  'proposed_components': instance.proposedComponents,
  'participant_message': instance.participantMessage,
  'requester_id': const IdConverter().toJson(instance.requesterId),
  'base_score_revision': instance.baseScoreRevision,
  'requested_at': const UtcTimestampConverter().toJson(instance.requestedAt),
  'state': _$ReviewRequestStateEnumMap[instance.state]!,
  'decision_actor_id': _$JsonConverterToJson<String, Id>(
    instance.decisionActorId,
    const IdConverter().toJson,
  ),
  'decision_time': _$JsonConverterToJson<String, DateTime>(
    instance.decisionTime,
    const UtcTimestampConverter().toJson,
  ),
  'decision_message': instance.decisionMessage,
  'resulting_attempt_id': _$JsonConverterToJson<String, Id>(
    instance.resultingAttemptId,
    const IdConverter().toJson,
  ),
  'revision': instance.revision,
};

const _$ReviewRequestStateEnumMap = {
  ReviewRequestState.submitted: 'Submitted',
  ReviewRequestState.underReview: 'UnderReview',
  ReviewRequestState.approved: 'Approved',
  ReviewRequestState.rejected: 'Rejected',
  ReviewRequestState.superseded: 'Superseded',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
