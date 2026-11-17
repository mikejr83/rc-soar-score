// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_change_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncChangeDto _$SyncChangeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SyncChangeDto',
      json,
      ($checkedConvert) {
        final val = SyncChangeDto(
          sequence: $checkedConvert('sequence', (v) => (v as num).toInt()),
          entityType: $checkedConvert('entity_type', (v) => v as String),
          entityId: $checkedConvert(
            'entity_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          revision: $checkedConvert('revision', (v) => (v as num).toInt()),
          payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>),
          aggregateId: $checkedConvert(
            'aggregate_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'entityType': 'entity_type',
        'entityId': 'entity_id',
        'aggregateId': 'aggregate_id',
      },
    );

Map<String, dynamic> _$SyncChangeDtoToJson(SyncChangeDto instance) =>
    <String, dynamic>{
      'sequence': instance.sequence,
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'revision': instance.revision,
      'payload': instance.payload,
      'aggregate_id': _$JsonConverterToJson<String, Id>(
        instance.aggregateId,
        const IdConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
