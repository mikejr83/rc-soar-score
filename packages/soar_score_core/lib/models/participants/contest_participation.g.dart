// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_participation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestParticipation _$ContestParticipationFromJson(
  Map<String, dynamic> json,
) => ContestParticipation(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  participantProfileId: const IdConverter().fromJson(
    json['participant_profile_id'] as String,
  ),
  classification: json['classification'] as String?,
  roleId: const IdConverter().fromJson(json['role_id'] as String),
  roleName: json['role_name'] as String,
  roleType:
      $enumDecodeNullable(_$RoleTypeEnumMap, json['role_type']) ??
      RoleType.pilot,
  participantNumber: (json['participant_number'] as num?)?.toInt(),
  scoringUuid: const ScoringUuidConverter().fromJson(
    json['scoring_uuid'] as String,
  ),
  retiredAtRound: (json['retired_at_round'] as num?)?.toInt(),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ContestParticipationToJson(
  ContestParticipation instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'participant_profile_id': const IdConverter().toJson(
    instance.participantProfileId,
  ),
  'classification': instance.classification,
  'role_id': const IdConverter().toJson(instance.roleId),
  'role_name': instance.roleName,
  'role_type': _$RoleTypeEnumMap[instance.roleType]!,
  'participant_number': instance.participantNumber,
  'scoring_uuid': const ScoringUuidConverter().toJson(instance.scoringUuid),
  'retired_at_round': instance.retiredAtRound,
  'revision': instance.revision,
};

const _$RoleTypeEnumMap = {
  RoleType.pilot: 'Pilot',
  RoleType.nonFlier: 'NonFlier',
};
