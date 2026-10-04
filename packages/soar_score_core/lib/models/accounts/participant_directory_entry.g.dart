// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_directory_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantDirectoryEntry _$ParticipantDirectoryEntryFromJson(
  Map<String, dynamic> json,
) => ParticipantDirectoryEntry(
  id: const IdConverter().fromJson(json['id'] as String),
  accountId: const IdConverter().fromJson(json['account_id'] as String),
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  club: json['club'] as String?,
  faiNumber: json['fai_number'] as String?,
  nationalOrgId: json['national_org_id'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  country: json['country'] as String?,
  isListed: json['is_listed'] as bool? ?? false,
  emailVisibleToDirectors: json['email_visible_to_directors'] as bool? ?? false,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  updatedAt: const UtcTimestampConverter().fromJson(
    json['updated_at'] as String,
  ),
);

Map<String, dynamic> _$ParticipantDirectoryEntryToJson(
  ParticipantDirectoryEntry instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'account_id': const IdConverter().toJson(instance.accountId),
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
