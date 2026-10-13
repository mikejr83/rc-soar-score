// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_mutation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncMutationDto _$SyncMutationDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SyncMutationDto',
      json,
      ($checkedConvert) {
        final val = SyncMutationDto(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          clientMutationId: $checkedConvert(
            'client_mutation_id',
            (v) => v as String,
          ),
          entityType: $checkedConvert('entity_type', (v) => v as String),
          entityId: $checkedConvert(
            'entity_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          authority: $checkedConvert(
            'authority',
            (v) => $enumDecode(_$AuthorityEnumMap, v),
          ),
          clientTime: $checkedConvert(
            'client_time',
            (v) => DateTime.parse(v as String),
          ),
          payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>),
          baseRevision: $checkedConvert(
            'base_revision',
            (v) => (v as num?)?.toInt(),
          ),
          dependsOnMutationId: $checkedConvert(
            'depends_on_mutation_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientMutationId': 'client_mutation_id',
        'entityType': 'entity_type',
        'entityId': 'entity_id',
        'clientTime': 'client_time',
        'baseRevision': 'base_revision',
        'dependsOnMutationId': 'depends_on_mutation_id',
      },
    );

Map<String, dynamic> _$SyncMutationDtoToJson(SyncMutationDto instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'client_mutation_id': instance.clientMutationId,
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'base_revision': instance.baseRevision,
      'authority': _$AuthorityEnumMap[instance.authority]!,
      'client_time': instance.clientTime.toIso8601String(),
      'depends_on_mutation_id': _$JsonConverterToJson<String, Id>(
        instance.dependsOnMutationId,
        const IdConverter().toJson,
      ),
      'payload': instance.payload,
    };

const _$AuthorityEnumMap = {
  Authority.director: 'Director',
  Authority.participant: 'Participant',
  Authority.helper: 'Helper',
  Authority.system: 'System',
  Authority.administrator: 'Administrator',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
