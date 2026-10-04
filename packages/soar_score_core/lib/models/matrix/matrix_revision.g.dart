// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_revision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatrixRevision _$MatrixRevisionFromJson(Map<String, dynamic> json) =>
    MatrixRevision(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      revisionNumber: (json['revision_number'] as num).toInt(),
      previousRevisionId: _$JsonConverterFromJson<String, Id>(
        json['previous_revision_id'],
        const IdConverter().fromJson,
      ),
      firstRound: (json['first_round'] as num).toInt(),
      lastRound: (json['last_round'] as num).toInt(),
      drawMode: $enumDecode(_$DrawModeEnumMap, json['draw_mode']),
      randomSeed: (json['random_seed'] as num).toInt(),
      algorithmVersion: json['algorithm_version'] as String,
      drawConfig: json['draw_config'] as Map<String, dynamic>,
      seedingSnapshot: json['seeding_snapshot'] as Map<String, dynamic>,
      fairnessSummary: json['fairness_summary'] as Map<String, dynamic>?,
      reason: json['reason'] as String?,
      createdBy: const IdConverter().fromJson(json['created_by'] as String),
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
      finalizedBy: _$JsonConverterFromJson<String, Id>(
        json['finalized_by'],
        const IdConverter().fromJson,
      ),
      finalizedAt: _$JsonConverterFromJson<String, DateTime>(
        json['finalized_at'],
        const UtcTimestampConverter().fromJson,
      ),
    );

Map<String, dynamic> _$MatrixRevisionToJson(MatrixRevision instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'revision_number': instance.revisionNumber,
      'previous_revision_id': _$JsonConverterToJson<String, Id>(
        instance.previousRevisionId,
        const IdConverter().toJson,
      ),
      'first_round': instance.firstRound,
      'last_round': instance.lastRound,
      'draw_mode': _$DrawModeEnumMap[instance.drawMode]!,
      'random_seed': instance.randomSeed,
      'algorithm_version': instance.algorithmVersion,
      'draw_config': instance.drawConfig,
      'seeding_snapshot': instance.seedingSnapshot,
      'fairness_summary': instance.fairnessSummary,
      'reason': instance.reason,
      'created_by': const IdConverter().toJson(instance.createdBy),
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
      'finalized_by': _$JsonConverterToJson<String, Id>(
        instance.finalizedBy,
        const IdConverter().toJson,
      ),
      'finalized_at': _$JsonConverterToJson<String, DateTime>(
        instance.finalizedAt,
        const UtcTimestampConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$DrawModeEnumMap = {
  DrawMode.standardManOnMan: 'StandardManOnMan',
  DrawMode.seededManOnMan: 'SeededManOnMan',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
