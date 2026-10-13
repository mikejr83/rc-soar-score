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
        );
        return val;
      },
      fieldKeyMap: const {'entityType': 'entity_type', 'entityId': 'entity_id'},
    );

Map<String, dynamic> _$SyncChangeDtoToJson(SyncChangeDto instance) =>
    <String, dynamic>{
      'sequence': instance.sequence,
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'revision': instance.revision,
      'payload': instance.payload,
    };
