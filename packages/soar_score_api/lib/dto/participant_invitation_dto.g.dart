// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolveInvitationRequest _$ResolveInvitationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ResolveInvitationRequest', json, ($checkedConvert) {
  final val = ResolveInvitationRequest(
    credential: $checkedConvert('credential', (v) => v as String),
    deviceId: $checkedConvert('device_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'deviceId': 'device_id'});

Map<String, dynamic> _$ResolveInvitationRequestToJson(
  ResolveInvitationRequest instance,
) => <String, dynamic>{
  'credential': instance.credential,
  'device_id': instance.deviceId,
};

ParticipantContestDto _$ParticipantContestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ParticipantContestDto',
  json,
  ($checkedConvert) {
    final val = ParticipantContestDto(
      contestId: $checkedConvert(
        'contest_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      name: $checkedConvert('name', (v) => v as String),
      disciplineType: $checkedConvert('discipline_type', (v) => v as String),
      lifecycle: $checkedConvert('lifecycle', (v) => v as String),
      scoringAccess: $checkedConvert('scoring_access', (v) => v as String),
      roundCount: $checkedConvert('round_count', (v) => (v as num).toInt()),
      timeZone: $checkedConvert('time_zone', (v) => v as String?),
      publicResultsUrl: $checkedConvert(
        'public_results_url',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'contestId': 'contest_id',
    'disciplineType': 'discipline_type',
    'scoringAccess': 'scoring_access',
    'roundCount': 'round_count',
    'timeZone': 'time_zone',
    'publicResultsUrl': 'public_results_url',
  },
);

Map<String, dynamic> _$ParticipantContestDtoToJson(
  ParticipantContestDto instance,
) => <String, dynamic>{
  'contest_id': const IdConverter().toJson(instance.contestId),
  'name': instance.name,
  'discipline_type': instance.disciplineType,
  'lifecycle': instance.lifecycle,
  'scoring_access': instance.scoringAccess,
  'round_count': instance.roundCount,
  'time_zone': instance.timeZone,
  'public_results_url': instance.publicResultsUrl,
};

ParticipantLinkDto _$ParticipantLinkDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ParticipantLinkDto',
      json,
      ($checkedConvert) {
        final val = ParticipantLinkDto(
          participationId: $checkedConvert(
            'participation_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          pilotName: $checkedConvert('pilot_name', (v) => v as String),
          pilotNumber: $checkedConvert(
            'pilot_number',
            (v) => (v as num).toInt(),
          ),
          role: $checkedConvert('role', (v) => v as String),
          teamName: $checkedConvert('team_name', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'participationId': 'participation_id',
        'pilotName': 'pilot_name',
        'pilotNumber': 'pilot_number',
        'teamName': 'team_name',
      },
    );

Map<String, dynamic> _$ParticipantLinkDtoToJson(ParticipantLinkDto instance) =>
    <String, dynamic>{
      'participation_id': const IdConverter().toJson(instance.participationId),
      'pilot_name': instance.pilotName,
      'pilot_number': instance.pilotNumber,
      'role': instance.role,
      'team_name': instance.teamName,
    };

ResolveInvitationResponse _$ResolveInvitationResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ResolveInvitationResponse',
  json,
  ($checkedConvert) {
    final val = ResolveInvitationResponse(
      sessionToken: $checkedConvert('session_token', (v) => v as String),
      sessionExpiresAt: $checkedConvert(
        'session_expires_at',
        (v) => DateTime.parse(v as String),
      ),
      contest: $checkedConvert(
        'contest',
        (v) => ParticipantContestDto.fromJson(v as Map<String, dynamic>),
      ),
      participant: $checkedConvert(
        'participant',
        (v) => ParticipantLinkDto.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'sessionToken': 'session_token',
    'sessionExpiresAt': 'session_expires_at',
  },
);

Map<String, dynamic> _$ResolveInvitationResponseToJson(
  ResolveInvitationResponse instance,
) => <String, dynamic>{
  'session_token': instance.sessionToken,
  'session_expires_at': instance.sessionExpiresAt.toIso8601String(),
  'contest': instance.contest,
  'participant': instance.participant,
};
