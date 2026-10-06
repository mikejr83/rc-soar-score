// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_participation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddParticipationRequest _$AddParticipationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AddParticipationRequest',
  json,
  ($checkedConvert) {
    final val = AddParticipationRequest(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      participantProfileId: $checkedConvert(
        'participant_profile_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      roleId: $checkedConvert(
        'role_id',
        (v) => _$JsonConverterFromJson<String, Id>(
          v,
          const IdConverter().fromJson,
        ),
      ),
      classification: $checkedConvert('classification', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'participantProfileId': 'participant_profile_id',
    'roleId': 'role_id',
  },
);

Map<String, dynamic> _$AddParticipationRequestToJson(
  AddParticipationRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'participant_profile_id': const IdConverter().toJson(
    instance.participantProfileId,
  ),
  'role_id': _$JsonConverterToJson<String, Id>(
    instance.roleId,
    const IdConverter().toJson,
  ),
  'classification': instance.classification,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
