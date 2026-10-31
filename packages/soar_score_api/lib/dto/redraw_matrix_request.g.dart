// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redraw_matrix_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedrawMatrixRequest _$RedrawMatrixRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'RedrawMatrixRequest',
      json,
      ($checkedConvert) {
        final val = RedrawMatrixRequest(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          firstRound: $checkedConvert('first_round', (v) => (v as num).toInt()),
          rounds: $checkedConvert('rounds', (v) => (v as num).toInt()),
          groupsPerRound: $checkedConvert(
            'groups_per_round',
            (v) => (v as num).toInt(),
          ),
          randomSeed: $checkedConvert(
            'random_seed',
            (v) => (v as num?)?.toInt(),
          ),
          attemptsPerRound: $checkedConvert(
            'attempts_per_round',
            (v) => (v as num?)?.toInt(),
          ),
          seedCount: $checkedConvert('seed_count', (v) => (v as num?)?.toInt()),
          reason: $checkedConvert('reason', (v) => v as String?),
          baseMatrixRevision: $checkedConvert(
            'base_matrix_revision',
            (v) => (v as num).toInt(),
          ),
          preview: $checkedConvert('preview', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstRound': 'first_round',
        'groupsPerRound': 'groups_per_round',
        'randomSeed': 'random_seed',
        'attemptsPerRound': 'attempts_per_round',
        'seedCount': 'seed_count',
        'baseMatrixRevision': 'base_matrix_revision',
      },
    );

Map<String, dynamic> _$RedrawMatrixRequestToJson(
  RedrawMatrixRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'first_round': instance.firstRound,
  'rounds': instance.rounds,
  'groups_per_round': instance.groupsPerRound,
  'random_seed': instance.randomSeed,
  'attempts_per_round': instance.attemptsPerRound,
  'seed_count': instance.seedCount,
  'reason': instance.reason,
  'base_matrix_revision': instance.baseMatrixRevision,
  'preview': instance.preview,
};
