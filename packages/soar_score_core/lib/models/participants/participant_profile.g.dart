// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantProfile _$ParticipantProfileFromJson(Map<String, dynamic> json) =>
    ParticipantProfile(
      id: const IdConverter().fromJson(json['id'] as String),
      ownerAccountId: const IdConverter().fromJson(
        json['owner_account_id'] as String,
      ),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      club: json['club'] as String?,
      faiNumber: json['fai_number'] as String?,
      nationalOrgId: json['national_org_id'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      email: json['email'] as String?,
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
      updatedAt: const UtcTimestampConverter().fromJson(
        json['updated_at'] as String,
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ParticipantProfileToJson(ParticipantProfile instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'owner_account_id': const IdConverter().toJson(instance.ownerAccountId),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'club': instance.club,
      'fai_number': instance.faiNumber,
      'national_org_id': instance.nationalOrgId,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'email': instance.email,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
      'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
      'revision': instance.revision,
    };
