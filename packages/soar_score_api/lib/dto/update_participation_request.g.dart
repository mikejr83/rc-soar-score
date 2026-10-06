// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_participation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateParticipationRequest _$UpdateParticipationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateParticipationRequest',
  json,
  ($checkedConvert) {
    final val = UpdateParticipationRequest(
      baseRevision: $checkedConvert('base_revision', (v) => (v as num).toInt()),
      roleId: $checkedConvert(
        'role_id',
        (v) => _$JsonConverterFromJson<String, Id>(
          v,
          const IdConverter().fromJson,
        ),
      ),
      classification: $checkedConvert('classification', (v) => v as String?),
      retiredAtRound: $checkedConvert(
        'retired_at_round',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'baseRevision': 'base_revision',
    'roleId': 'role_id',
    'retiredAtRound': 'retired_at_round',
  },
);

Map<String, dynamic> _$UpdateParticipationRequestToJson(
  UpdateParticipationRequest instance,
) => <String, dynamic>{
  'base_revision': instance.baseRevision,
  'role_id': _$JsonConverterToJson<String, Id>(
    instance.roleId,
    const IdConverter().toJson,
  ),
  'classification': instance.classification,
  'retired_at_round': instance.retiredAtRound,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
