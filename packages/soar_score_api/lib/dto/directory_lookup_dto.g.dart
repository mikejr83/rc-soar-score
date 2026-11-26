// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_lookup_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectoryLookupRequest _$DirectoryLookupRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DirectoryLookupRequest', json, ($checkedConvert) {
  final val = DirectoryLookupRequest(
    key: $checkedConvert(
      'key',
      (v) => $enumDecode(_$DirectoryLookupKeyDtoEnumMap, v),
    ),
    value: $checkedConvert('value', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DirectoryLookupRequestToJson(
  DirectoryLookupRequest instance,
) => <String, dynamic>{
  'key': _$DirectoryLookupKeyDtoEnumMap[instance.key]!,
  'value': instance.value,
};

const _$DirectoryLookupKeyDtoEnumMap = {
  DirectoryLookupKeyDto.email: 'email',
  DirectoryLookupKeyDto.faiNumber: 'fai_number',
  DirectoryLookupKeyDto.nationalOrgId: 'national_org_id',
};

DirectoryMatchDto _$DirectoryMatchDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DirectoryMatchDto',
      json,
      ($checkedConvert) {
        final val = DirectoryMatchDto(
          entryId: $checkedConvert(
            'entry_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          firstName: $checkedConvert('first_name', (v) => v as String),
          lastName: $checkedConvert('last_name', (v) => v as String),
          club: $checkedConvert('club', (v) => v as String?),
          faiNumber: $checkedConvert('fai_number', (v) => v as String?),
          nationalOrgId: $checkedConvert(
            'national_org_id',
            (v) => v as String?,
          ),
          city: $checkedConvert('city', (v) => v as String?),
          state: $checkedConvert('state', (v) => v as String?),
          country: $checkedConvert('country', (v) => v as String?),
          email: $checkedConvert('email', (v) => v as String?),
          emailAvailable: $checkedConvert('email_available', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'entryId': 'entry_id',
        'firstName': 'first_name',
        'lastName': 'last_name',
        'faiNumber': 'fai_number',
        'nationalOrgId': 'national_org_id',
        'emailAvailable': 'email_available',
      },
    );

Map<String, dynamic> _$DirectoryMatchDtoToJson(DirectoryMatchDto instance) =>
    <String, dynamic>{
      'entry_id': const IdConverter().toJson(instance.entryId),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'club': instance.club,
      'fai_number': instance.faiNumber,
      'national_org_id': instance.nationalOrgId,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'email': instance.email,
      'email_available': instance.emailAvailable,
    };

DirectoryLookupResponse _$DirectoryLookupResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DirectoryLookupResponse', json, ($checkedConvert) {
  final val = DirectoryLookupResponse(
    results: $checkedConvert(
      'results',
      (v) => (v as List<dynamic>)
          .map((e) => DirectoryMatchDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$DirectoryLookupResponseToJson(
  DirectoryLookupResponse instance,
) => <String, dynamic>{
  'results': instance.results.map((e) => e.toJson()).toList(),
};

DirectoryCopyRequest _$DirectoryCopyRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DirectoryCopyRequest', json, ($checkedConvert) {
  final val = DirectoryCopyRequest(
    entryId: $checkedConvert(
      'entry_id',
      (v) => const IdConverter().fromJson(v as String),
    ),
    profileId: $checkedConvert(
      'profile_id',
      (v) => const IdConverter().fromJson(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'entryId': 'entry_id', 'profileId': 'profile_id'});

Map<String, dynamic> _$DirectoryCopyRequestToJson(
  DirectoryCopyRequest instance,
) => <String, dynamic>{
  'entry_id': const IdConverter().toJson(instance.entryId),
  'profile_id': const IdConverter().toJson(instance.profileId),
};
