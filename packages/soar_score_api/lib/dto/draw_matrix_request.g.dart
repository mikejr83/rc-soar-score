// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_matrix_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawMatrixRequest _$DrawMatrixRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DrawMatrixRequest',
      json,
      ($checkedConvert) {
        final val = DrawMatrixRequest(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
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
        );
        return val;
      },
      fieldKeyMap: const {
        'groupsPerRound': 'groups_per_round',
        'randomSeed': 'random_seed',
        'attemptsPerRound': 'attempts_per_round',
        'seedCount': 'seed_count',
      },
    );

Map<String, dynamic> _$DrawMatrixRequestToJson(DrawMatrixRequest instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'rounds': instance.rounds,
      'groups_per_round': instance.groupsPerRound,
      'random_seed': instance.randomSeed,
      'attempts_per_round': instance.attemptsPerRound,
      'seed_count': instance.seedCount,
    };
