// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_participation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountParticipationDto _$AccountParticipationDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AccountParticipationDto',
  json,
  ($checkedConvert) {
    final val = AccountParticipationDto(
      participationId: $checkedConvert(
        'participation_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      contestId: $checkedConvert(
        'contest_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      contestName: $checkedConvert('contest_name', (v) => v as String),
      startDateTime: $checkedConvert(
        'start_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      endDateTime: $checkedConvert(
        'end_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      startDate: $checkedConvert('start_date', (v) => v as String),
      endDate: $checkedConvert('end_date', (v) => v as String),
      timezone: $checkedConvert('timezone', (v) => v as String),
      phase: $checkedConvert('phase', (v) => v as String),
      readOnly: $checkedConvert('read_only', (v) => v as bool),
      host: $checkedConvert('host', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String?),
      publicResultsUrl: $checkedConvert(
        'public_results_url',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'participationId': 'participation_id',
    'contestId': 'contest_id',
    'contestName': 'contest_name',
    'startDateTime': 'start_date_time',
    'endDateTime': 'end_date_time',
    'startDate': 'start_date',
    'endDate': 'end_date',
    'readOnly': 'read_only',
    'publicResultsUrl': 'public_results_url',
  },
);

Map<String, dynamic> _$AccountParticipationDtoToJson(
  AccountParticipationDto instance,
) => <String, dynamic>{
  'participation_id': const IdConverter().toJson(instance.participationId),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'contest_name': instance.contestName,
  'start_date_time': const UtcTimestampConverter().toJson(
    instance.startDateTime,
  ),
  'end_date_time': const UtcTimestampConverter().toJson(instance.endDateTime),
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'timezone': instance.timezone,
  'phase': instance.phase,
  'read_only': instance.readOnly,
  'host': instance.host,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
  'public_results_url': instance.publicResultsUrl,
};

AccountParticipationsDto _$AccountParticipationsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AccountParticipationsDto', json, ($checkedConvert) {
  final val = AccountParticipationsDto(
    participations: $checkedConvert(
      'participations',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) =>
                    AccountParticipationDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    ),
  );
  return val;
});

Map<String, dynamic> _$AccountParticipationsDtoToJson(
  AccountParticipationsDto instance,
) => <String, dynamic>{
  'participations': instance.participations.map((e) => e.toJson()).toList(),
};

LinkCandidateContestDto _$LinkCandidateContestDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'LinkCandidateContestDto',
  json,
  ($checkedConvert) {
    final val = LinkCandidateContestDto(
      name: $checkedConvert('name', (v) => v as String),
      startDateTime: $checkedConvert(
        'start_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      endDateTime: $checkedConvert(
        'end_date_time',
        (v) => const UtcTimestampConverter().fromJson(v as String),
      ),
      timezone: $checkedConvert('timezone', (v) => v as String),
      host: $checkedConvert('host', (v) => v as String?),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'startDateTime': 'start_date_time',
    'endDateTime': 'end_date_time',
  },
);

Map<String, dynamic> _$LinkCandidateContestDtoToJson(
  LinkCandidateContestDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'start_date_time': const UtcTimestampConverter().toJson(
    instance.startDateTime,
  ),
  'end_date_time': const UtcTimestampConverter().toJson(instance.endDateTime),
  'timezone': instance.timezone,
  'host': instance.host,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
};

LinkCandidateDto _$LinkCandidateDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LinkCandidateDto', json, ($checkedConvert) {
  final val = LinkCandidateDto(
    id: $checkedConvert('id', (v) => const IdConverter().fromJson(v as String)),
    firstName: $checkedConvert('first_name', (v) => v as String),
    lastName: $checkedConvert('last_name', (v) => v as String),
    contests: $checkedConvert(
      'contests',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) =>
                    LinkCandidateContestDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    ),
  );
  return val;
}, fieldKeyMap: const {'firstName': 'first_name', 'lastName': 'last_name'});

Map<String, dynamic> _$LinkCandidateDtoToJson(LinkCandidateDto instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'contests': instance.contests.map((e) => e.toJson()).toList(),
    };

LinkCandidatesDto _$LinkCandidatesDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LinkCandidatesDto', json, ($checkedConvert) {
      final val = LinkCandidatesDto(
        candidates: $checkedConvert(
          'candidates',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => LinkCandidateDto.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              const [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$LinkCandidatesDtoToJson(LinkCandidatesDto instance) =>
    <String, dynamic>{
      'candidates': instance.candidates.map((e) => e.toJson()).toList(),
    };

AccountLinkDto _$AccountLinkDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AccountLinkDto',
      json,
      ($checkedConvert) {
        final val = AccountLinkDto(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          pilotName: $checkedConvert('pilot_name', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$ParticipantLinkStatusEnumMap, v),
          ),
          origin: $checkedConvert(
            'origin',
            (v) => $enumDecode(_$ParticipantLinkOriginEnumMap, v),
          ),
          confirmedAt: $checkedConvert(
            'confirmed_at',
            (v) => _$JsonConverterFromJson<String, DateTime>(
              v,
              const UtcTimestampConverter().fromJson,
            ),
          ),
          endedAt: $checkedConvert(
            'ended_at',
            (v) => _$JsonConverterFromJson<String, DateTime>(
              v,
              const UtcTimestampConverter().fromJson,
            ),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'pilotName': 'pilot_name',
        'confirmedAt': 'confirmed_at',
        'endedAt': 'ended_at',
      },
    );

Map<String, dynamic> _$AccountLinkDtoToJson(AccountLinkDto instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'pilot_name': instance.pilotName,
      'status': _$ParticipantLinkStatusEnumMap[instance.status]!,
      'origin': _$ParticipantLinkOriginEnumMap[instance.origin]!,
      'confirmed_at': _$JsonConverterToJson<String, DateTime>(
        instance.confirmedAt,
        const UtcTimestampConverter().toJson,
      ),
      'ended_at': _$JsonConverterToJson<String, DateTime>(
        instance.endedAt,
        const UtcTimestampConverter().toJson,
      ),
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

AccountLinksDto _$AccountLinksDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountLinksDto', json, ($checkedConvert) {
      final val = AccountLinksDto(
        links: $checkedConvert(
          'links',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => AccountLinkDto.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              const [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$AccountLinksDtoToJson(AccountLinksDto instance) =>
    <String, dynamic>{'links': instance.links.map((e) => e.toJson()).toList()};
