// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_participant_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateParticipantRequest _$CreateParticipantRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateParticipantRequest',
  json,
  ($checkedConvert) {
    final val = CreateParticipantRequest(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      firstName: $checkedConvert('first_name', (v) => v as String),
      lastName: $checkedConvert('last_name', (v) => v as String),
      club: $checkedConvert('club', (v) => v as String?),
      faiNumber: $checkedConvert('fai_number', (v) => v as String?),
      nationalOrgId: $checkedConvert('national_org_id', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String?),
      email: $checkedConvert('email', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstName': 'first_name',
    'lastName': 'last_name',
    'faiNumber': 'fai_number',
    'nationalOrgId': 'national_org_id',
  },
);

Map<String, dynamic> _$CreateParticipantRequestToJson(
  CreateParticipantRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'club': instance.club,
  'fai_number': instance.faiNumber,
  'national_org_id': instance.nationalOrgId,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
  'email': instance.email,
};
