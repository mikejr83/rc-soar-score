// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matrix_revision_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatrixRevisionSummary _$MatrixRevisionSummaryFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MatrixRevisionSummary',
  json,
  ($checkedConvert) {
    final val = MatrixRevisionSummary(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      revisionNumber: $checkedConvert(
        'revision_number',
        (v) => (v as num).toInt(),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      reason: $checkedConvert('reason', (v) => v as String?),
      createdBy: $checkedConvert(
        'created_by',
        (v) => const IdConverter().fromJson(v as String),
      ),
      firstRound: $checkedConvert('first_round', (v) => (v as num).toInt()),
      lastRound: $checkedConvert('last_round', (v) => (v as num).toInt()),
      algorithmVersion: $checkedConvert(
        'algorithm_version',
        (v) => v as String,
      ),
      randomSeed: $checkedConvert('random_seed', (v) => (v as num).toInt()),
      fairnessScore: $checkedConvert('fairness_score', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {
    'revisionNumber': 'revision_number',
    'createdAt': 'created_at',
    'createdBy': 'created_by',
    'firstRound': 'first_round',
    'lastRound': 'last_round',
    'algorithmVersion': 'algorithm_version',
    'randomSeed': 'random_seed',
    'fairnessScore': 'fairness_score',
  },
);

Map<String, dynamic> _$MatrixRevisionSummaryToJson(
  MatrixRevisionSummary instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'revision_number': instance.revisionNumber,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'reason': instance.reason,
  'created_by': const IdConverter().toJson(instance.createdBy),
  'first_round': instance.firstRound,
  'last_round': instance.lastRound,
  'algorithm_version': instance.algorithmVersion,
  'random_seed': instance.randomSeed,
  'fairness_score': instance.fairnessScore,
};
