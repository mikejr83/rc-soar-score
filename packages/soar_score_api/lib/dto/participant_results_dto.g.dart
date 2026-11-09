// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant_results_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParticipantGroupRowDto _$ParticipantGroupRowDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ParticipantGroupRowDto',
  json,
  ($checkedConvert) {
    final val = ParticipantGroupRowDto(
      pilotName: $checkedConvert('pilot_name', (v) => v as String),
      pilotNumber: $checkedConvert('pilot_number', (v) => (v as num?)?.toInt()),
      state: $checkedConvert(
        'state',
        (v) => $enumDecode(_$ParticipantScoreStateEnumMap, v),
      ),
      isYou: $checkedConvert('is_you', (v) => v as bool),
      isEstimate: $checkedConvert('is_estimate', (v) => v as bool),
      timeFlownSeconds: $checkedConvert(
        'time_flown_seconds',
        (v) => (v as num?)?.toInt(),
      ),
      launchHeight: $checkedConvert('launch_height', (v) => v as num?),
      landing: $checkedConvert('landing', (v) => v as String?),
      flightScore: $checkedConvert('flight_score', (v) => v as num?),
      rawScore: $checkedConvert('raw_score', (v) => v as num?),
      roundScore: $checkedConvert('round_score', (v) => v as num?),
      zeroReason: $checkedConvert('zero_reason', (v) => v as String?),
      reviewPending: $checkedConvert(
        'review_pending',
        (v) => v as bool? ?? false,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'pilotName': 'pilot_name',
    'pilotNumber': 'pilot_number',
    'isYou': 'is_you',
    'isEstimate': 'is_estimate',
    'timeFlownSeconds': 'time_flown_seconds',
    'launchHeight': 'launch_height',
    'flightScore': 'flight_score',
    'rawScore': 'raw_score',
    'roundScore': 'round_score',
    'zeroReason': 'zero_reason',
    'reviewPending': 'review_pending',
  },
);

Map<String, dynamic> _$ParticipantGroupRowDtoToJson(
  ParticipantGroupRowDto instance,
) => <String, dynamic>{
  'pilot_name': instance.pilotName,
  'pilot_number': instance.pilotNumber,
  'state': _$ParticipantScoreStateEnumMap[instance.state]!,
  'is_you': instance.isYou,
  'is_estimate': instance.isEstimate,
  'time_flown_seconds': instance.timeFlownSeconds,
  'launch_height': instance.launchHeight,
  'landing': instance.landing,
  'flight_score': instance.flightScore,
  'raw_score': instance.rawScore,
  'round_score': instance.roundScore,
  'zero_reason': instance.zeroReason,
  'review_pending': instance.reviewPending,
};

const _$ParticipantScoreStateEnumMap = {
  ParticipantScoreState.notEntered: 'not_entered',
  ParticipantScoreState.draft: 'draft',
  ParticipantScoreState.submitted: 'submitted',
  ParticipantScoreState.reviewRequested: 'review_requested',
  ParticipantScoreState.underReview: 'under_review',
  ParticipantScoreState.official: 'official',
  ParticipantScoreState.locked: 'locked',
  ParticipantScoreState.zero: 'zero',
  ParticipantScoreState.retired: 'retired',
};

ParticipantGroupResultsDto _$ParticipantGroupResultsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ParticipantGroupResultsDto',
  json,
  ($checkedConvert) {
    final val = ParticipantGroupResultsDto(
      round: $checkedConvert('round', (v) => (v as num).toInt()),
      group: $checkedConvert('group', (v) => v as String),
      latestRound: $checkedConvert('latest_round', (v) => (v as num).toInt()),
      preliminary: $checkedConvert('preliminary', (v) => v as bool),
      rows: $checkedConvert(
        'rows',
        (v) => (v as List<dynamic>)
            .map(
              (e) => ParticipantGroupRowDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      pendingReviewAffectsPlacement: $checkedConvert(
        'pending_review_affects_placement',
        (v) => v as bool? ?? false,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'latestRound': 'latest_round',
    'pendingReviewAffectsPlacement': 'pending_review_affects_placement',
  },
);

Map<String, dynamic> _$ParticipantGroupResultsDtoToJson(
  ParticipantGroupResultsDto instance,
) => <String, dynamic>{
  'round': instance.round,
  'group': instance.group,
  'latest_round': instance.latestRound,
  'preliminary': instance.preliminary,
  'rows': instance.rows,
  'pending_review_affects_placement': instance.pendingReviewAffectsPlacement,
};

ParticipantStandingDto _$ParticipantStandingDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ParticipantStandingDto',
  json,
  ($checkedConvert) {
    final val = ParticipantStandingDto(
      place: $checkedConvert('place', (v) => (v as num).toInt()),
      pilotName: $checkedConvert('pilot_name', (v) => v as String),
      pilotNumber: $checkedConvert('pilot_number', (v) => (v as num?)?.toInt()),
      score: $checkedConvert('score', (v) => v as num),
      isYou: $checkedConvert('is_you', (v) => v as bool),
      tied: $checkedConvert('tied', (v) => v as bool? ?? false),
    );
    return val;
  },
  fieldKeyMap: const {
    'pilotName': 'pilot_name',
    'pilotNumber': 'pilot_number',
    'isYou': 'is_you',
  },
);

Map<String, dynamic> _$ParticipantStandingDtoToJson(
  ParticipantStandingDto instance,
) => <String, dynamic>{
  'place': instance.place,
  'pilot_name': instance.pilotName,
  'pilot_number': instance.pilotNumber,
  'score': instance.score,
  'is_you': instance.isYou,
  'tied': instance.tied,
};

ParticipantOverallResultsDto _$ParticipantOverallResultsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ParticipantOverallResultsDto',
  json,
  ($checkedConvert) {
    final val = ParticipantOverallResultsDto(
      asOfRound: $checkedConvert('as_of_round', (v) => (v as num).toInt()),
      latestRound: $checkedConvert('latest_round', (v) => (v as num).toInt()),
      preliminary: $checkedConvert('preliminary', (v) => v as bool),
      standings: $checkedConvert(
        'standings',
        (v) => (v as List<dynamic>)
            .map(
              (e) => ParticipantStandingDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      heldAtRound: $checkedConvert(
        'held_at_round',
        (v) => (v as num?)?.toInt(),
      ),
      yourPlace: $checkedConvert('your_place', (v) => (v as num?)?.toInt()),
      yourScore: $checkedConvert('your_score', (v) => v as num?),
      teamStandings: $checkedConvert(
        'team_standings',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => ParticipantTeamStandingDto.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'asOfRound': 'as_of_round',
    'latestRound': 'latest_round',
    'heldAtRound': 'held_at_round',
    'yourPlace': 'your_place',
    'yourScore': 'your_score',
    'teamStandings': 'team_standings',
  },
);

Map<String, dynamic> _$ParticipantOverallResultsDtoToJson(
  ParticipantOverallResultsDto instance,
) => <String, dynamic>{
  'as_of_round': instance.asOfRound,
  'latest_round': instance.latestRound,
  'held_at_round': instance.heldAtRound,
  'preliminary': instance.preliminary,
  'your_place': instance.yourPlace,
  'your_score': instance.yourScore,
  'standings': instance.standings,
  'team_standings': instance.teamStandings,
};

ParticipantTeamStandingDto _$ParticipantTeamStandingDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ParticipantTeamStandingDto', json, ($checkedConvert) {
  final val = ParticipantTeamStandingDto(
    place: $checkedConvert('place', (v) => (v as num).toInt()),
    teamName: $checkedConvert('team_name', (v) => v as String),
    score: $checkedConvert('score', (v) => v as num),
    isYourTeam: $checkedConvert('is_your_team', (v) => v as bool),
    tied: $checkedConvert('tied', (v) => v as bool? ?? false),
  );
  return val;
}, fieldKeyMap: const {'teamName': 'team_name', 'isYourTeam': 'is_your_team'});

Map<String, dynamic> _$ParticipantTeamStandingDtoToJson(
  ParticipantTeamStandingDto instance,
) => <String, dynamic>{
  'place': instance.place,
  'team_name': instance.teamName,
  'score': instance.score,
  'is_your_team': instance.isYourTeam,
  'tied': instance.tied,
};
