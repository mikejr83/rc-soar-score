// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_account_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantAccountLink _$ParticipantAccountLinkFromJson(
  Map<String, dynamic> json,
) => ParticipantAccountLink(
  id: const IdConverter().fromJson(json['id'] as String),
  participantProfileId: const IdConverter().fromJson(
    json['participant_profile_id'] as String,
  ),
  accountId: const IdConverter().fromJson(json['account_id'] as String),
  status: $enumDecode(_$ParticipantLinkStatusEnumMap, json['status']),
  origin: $enumDecode(_$ParticipantLinkOriginEnumMap, json['origin']),
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  confirmedAt: _$JsonConverterFromJson<String, DateTime>(
    json['confirmed_at'],
    const UtcTimestampConverter().fromJson,
  ),
  endedAt: _$JsonConverterFromJson<String, DateTime>(
    json['ended_at'],
    const UtcTimestampConverter().fromJson,
  ),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ParticipantAccountLinkToJson(
  ParticipantAccountLink instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'participant_profile_id': const IdConverter().toJson(
    instance.participantProfileId,
  ),
  'account_id': const IdConverter().toJson(instance.accountId),
  'status': _$ParticipantLinkStatusEnumMap[instance.status]!,
  'origin': _$ParticipantLinkOriginEnumMap[instance.origin]!,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'confirmed_at': _$JsonConverterToJson<String, DateTime>(
    instance.confirmedAt,
    const UtcTimestampConverter().toJson,
  ),
  'ended_at': _$JsonConverterToJson<String, DateTime>(
    instance.endedAt,
    const UtcTimestampConverter().toJson,
  ),
  'revision': instance.revision,
};

const _$ParticipantLinkStatusEnumMap = {
  ParticipantLinkStatus.candidate: 'Candidate',
  ParticipantLinkStatus.confirmed: 'Confirmed',
  ParticipantLinkStatus.ended: 'Ended',
};

const _$ParticipantLinkOriginEnumMap = {
  ParticipantLinkOrigin.emailMatch: 'EmailMatch',
  ParticipantLinkOrigin.directoryPull: 'DirectoryPull',
  ParticipantLinkOrigin.invitationRedemption: 'InvitationRedemption',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
