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
      setBy: _$JsonConverterFromJson<String, Id>(
        json['set_by'],
        const IdConverter().fromJson,
      ),
      reason: json['reason'] as String,
      selectionOrigin:
          $enumDecodeNullable(
            _$SelectionOriginEnumMap,
            json['selection_origin'],
          ) ??
          SelectionOrigin.manual,
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
      'set_by': _$JsonConverterToJson<String, Id>(
        instance.setBy,
        const IdConverter().toJson,
      ),
      'reason': instance.reason,
      'selection_origin': _$SelectionOriginEnumMap[instance.selectionOrigin]!,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$SelectionOriginEnumMap = {
  SelectionOrigin.manual: 'Manual',
  SelectionOrigin.automatic: 'Automatic',
  SelectionOrigin.reviewDecision: 'ReviewDecision',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
