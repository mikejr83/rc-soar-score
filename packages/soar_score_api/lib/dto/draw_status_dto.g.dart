// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_status_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrawStatusDto _$DrawStatusDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DrawStatusDto', json, ($checkedConvert) {
      final val = DrawStatusDto(
        id: $checkedConvert(
          'id',
          (v) => const IdConverter().fromJson(v as String),
        ),
        state: $checkedConvert(
          'state',
          (v) => $enumDecode(_$DrawJobStateEnumMap, v),
        ),
        percent: $checkedConvert('percent', (v) => (v as num).toInt()),
        seed: $checkedConvert('seed', (v) => (v as num).toInt()),
        seedCount: $checkedConvert('seed_count', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'seedCount': 'seed_count'});

Map<String, dynamic> _$DrawStatusDtoToJson(DrawStatusDto instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'state': _$DrawJobStateEnumMap[instance.state]!,
      'percent': instance.percent,
      'seed': instance.seed,
      'seed_count': instance.seedCount,
    };

const _$DrawJobStateEnumMap = {
  DrawJobState.running: 'running',
  DrawJobState.completed: 'completed',
  DrawJobState.cancelled: 'cancelled',
  DrawJobState.failed: 'failed',
};
