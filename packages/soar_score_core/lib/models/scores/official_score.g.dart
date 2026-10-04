// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'official_score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfficialScore _$OfficialScoreFromJson(Map<String, dynamic> json) =>
    OfficialScore(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      scorePlaceholderId: const IdConverter().fromJson(
        json['score_placeholder_id'] as String,
      ),
      scoreAttemptId: const IdConverter().fromJson(
        json['score_attempt_id'] as String,
      ),
      scoreRevision: (json['score_revision'] as num).toInt(),
      components: json['components'] as Map<String, dynamic>,
      setAt: const UtcTimestampConverter().fromJson(json['set_at'] as String),
      setBy: const IdConverter().fromJson(json['set_by'] as String),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$OfficialScoreToJson(OfficialScore instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'score_placeholder_id': const IdConverter().toJson(
        instance.scorePlaceholderId,
      ),
      'score_attempt_id': const IdConverter().toJson(instance.scoreAttemptId),
      'score_revision': instance.scoreRevision,
      'components': instance.components,
      'set_at': const UtcTimestampConverter().toJson(instance.setAt),
      'set_by': const IdConverter().toJson(instance.setBy),
      'reason': instance.reason,
    };
