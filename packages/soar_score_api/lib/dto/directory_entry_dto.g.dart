// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutDirectoryEntryRequest _$PutDirectoryEntryRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PutDirectoryEntryRequest',
  json,
  ($checkedConvert) {
    final val = PutDirectoryEntryRequest(
      firstName: $checkedConvert('first_name', (v) => v as String),
      lastName: $checkedConvert('last_name', (v) => v as String),
      club: $checkedConvert('club', (v) => v as String?),
      faiNumber: $checkedConvert('fai_number', (v) => v as String?),
      nationalOrgId: $checkedConvert('national_org_id', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String?),
      isListed: $checkedConvert('is_listed', (v) => v as bool),
      emailVisibleToDirectors: $checkedConvert(
        'email_visible_to_directors',
        (v) => v as bool,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'firstName': 'first_name',
    'lastName': 'last_name',
    'faiNumber': 'fai_number',
    'nationalOrgId': 'national_org_id',
    'isListed': 'is_listed',
    'emailVisibleToDirectors': 'email_visible_to_directors',
  },
);

Map<String, dynamic> _$PutDirectoryEntryRequestToJson(
  PutDirectoryEntryRequest instance,
) => <String, dynamic>{
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'club': instance.club,
  'fai_number': instance.faiNumber,
  'national_org_id': instance.nationalOrgId,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
  'is_listed': instance.isListed,
  'email_visible_to_directors': instance.emailVisibleToDirectors,
};

DirectoryEntryStateDto _$DirectoryEntryStateDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DirectoryEntryStateDto',
  json,
  ($checkedConvert) {
    final val = DirectoryEntryStateDto(
      entry: $checkedConvert(
        'entry',
        (v) => v == null
            ? null
            : DirectoryEntryDto.fromJson(v as Map<String, dynamic>),
      ),
      suggestedFirstName: $checkedConvert(
        'suggested_first_name',
        (v) => v as String,
      ),
      suggestedLastName: $checkedConvert(
        'suggested_last_name',
        (v) => v as String,
      ),
      emailAvailable: $checkedConvert('email_available', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'suggestedFirstName': 'suggested_first_name',
    'suggestedLastName': 'suggested_last_name',
    'emailAvailable': 'email_available',
  },
);

Map<String, dynamic> _$DirectoryEntryStateDtoToJson(
  DirectoryEntryStateDto instance,
) => <String, dynamic>{
  'entry': instance.entry?.toJson(),
  'suggested_first_name': instance.suggestedFirstName,
  'suggested_last_name': instance.suggestedLastName,
  'email_available': instance.emailAvailable,
};

DirectoryEntryDto _$DirectoryEntryDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DirectoryEntryDto',
      json,
      ($checkedConvert) {
        final val = DirectoryEntryDto(
          id: $checkedConvert(
            'id',
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
          isListed: $checkedConvert('is_listed', (v) => v as bool),
          emailVisibleToDirectors: $checkedConvert(
            'email_visible_to_directors',
            (v) => v as bool,
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => const UtcTimestampConverter().fromJson(v as String),
          ),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => const UtcTimestampConverter().fromJson(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'firstName': 'first_name',
        'lastName': 'last_name',
        'faiNumber': 'fai_number',
        'nationalOrgId': 'national_org_id',
        'isListed': 'is_listed',
        'emailVisibleToDirectors': 'email_visible_to_directors',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$DirectoryEntryDtoToJson(DirectoryEntryDto instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'club': instance.club,
      'fai_number': instance.faiNumber,
      'national_org_id': instance.nationalOrgId,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'is_listed': instance.isListed,
      'email_visible_to_directors': instance.emailVisibleToDirectors,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
      'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
    };
