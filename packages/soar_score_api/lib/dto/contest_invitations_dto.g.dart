// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_invitations_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestInvitationDto _$ContestInvitationDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ContestInvitationDto',
  json,
  ($checkedConvert) {
    final val = ContestInvitationDto(
      participationId: $checkedConvert(
        'participation_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      link: $checkedConvert('link', (v) => v as String),
      emailStatus: $checkedConvert('email_status', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'participationId': 'participation_id',
    'emailStatus': 'email_status',
  },
);

Map<String, dynamic> _$ContestInvitationDtoToJson(
  ContestInvitationDto instance,
) => <String, dynamic>{
  'participation_id': const IdConverter().toJson(instance.participationId),
  'link': instance.link,
  'email_status': instance.emailStatus,
};

ContestInvitationsDto _$ContestInvitationsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ContestInvitationsDto',
  json,
  ($checkedConvert) {
    final val = ContestInvitationsDto(
      contestId: $checkedConvert(
        'contest_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      canIssue: $checkedConvert('can_issue', (v) => v as bool),
      cannotIssueCode: $checkedConvert(
        'cannot_issue_code',
        (v) => v as String?,
      ),
      cannotIssueReason: $checkedConvert(
        'cannot_issue_reason',
        (v) => v as String?,
      ),
      invitations: $checkedConvert(
        'invitations',
        (v) =>
            (v as List<dynamic>?)
                ?.map(
                  (e) =>
                      ContestInvitationDto.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      ),
      unreproducibleParticipationIds: $checkedConvert(
        'unreproducible_participation_ids',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => const IdConverter().fromJson(e as String))
                .toList() ??
            const [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'contestId': 'contest_id',
    'canIssue': 'can_issue',
    'cannotIssueCode': 'cannot_issue_code',
    'cannotIssueReason': 'cannot_issue_reason',
    'unreproducibleParticipationIds': 'unreproducible_participation_ids',
  },
);

Map<String, dynamic> _$ContestInvitationsDtoToJson(
  ContestInvitationsDto instance,
) => <String, dynamic>{
  'contest_id': const IdConverter().toJson(instance.contestId),
  'can_issue': instance.canIssue,
  'cannot_issue_code': instance.cannotIssueCode,
  'cannot_issue_reason': instance.cannotIssueReason,
  'invitations': instance.invitations.map((e) => e.toJson()).toList(),
  'unreproducible_participation_ids': instance.unreproducibleParticipationIds
      .map(const IdConverter().toJson)
      .toList(),
};

IssueInvitationsRequest _$IssueInvitationsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'IssueInvitationsRequest',
  json,
  ($checkedConvert) {
    final val = IssueInvitationsRequest(
      requestId: $checkedConvert('request_id', (v) => v as String),
      participationIds: $checkedConvert(
        'participation_ids',
        (v) => (v as List<dynamic>)
            .map((e) => const IdConverter().fromJson(e as String))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'requestId': 'request_id',
    'participationIds': 'participation_ids',
  },
);

Map<String, dynamic> _$IssueInvitationsRequestToJson(
  IssueInvitationsRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'participation_ids': instance.participationIds
      .map(const IdConverter().toJson)
      .toList(),
};

IssueInvitationsResponse _$IssueInvitationsResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('IssueInvitationsResponse', json, ($checkedConvert) {
  final val = IssueInvitationsResponse(
    issuedCount: $checkedConvert('issued_count', (v) => (v as num).toInt()),
    invitations: $checkedConvert(
      'invitations',
      (v) => (v as List<dynamic>)
          .map((e) => ContestInvitationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'issuedCount': 'issued_count'});

Map<String, dynamic> _$IssueInvitationsResponseToJson(
  IssueInvitationsResponse instance,
) => <String, dynamic>{
  'issued_count': instance.issuedCount,
  'invitations': instance.invitations.map((e) => e.toJson()).toList(),
};

EmailInvitationsRequest _$EmailInvitationsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'EmailInvitationsRequest',
  json,
  ($checkedConvert) {
    final val = EmailInvitationsRequest(
      requestId: $checkedConvert('request_id', (v) => v as String),
      participationIds: $checkedConvert(
        'participation_ids',
        (v) => (v as List<dynamic>)
            .map((e) => const IdConverter().fromJson(e as String))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'requestId': 'request_id',
    'participationIds': 'participation_ids',
  },
);

Map<String, dynamic> _$EmailInvitationsRequestToJson(
  EmailInvitationsRequest instance,
) => <String, dynamic>{
  'request_id': instance.requestId,
  'participation_ids': instance.participationIds
      .map(const IdConverter().toJson)
      .toList(),
};

EmailInvitationResultDto _$EmailInvitationResultDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EmailInvitationResultDto', json, ($checkedConvert) {
  final val = EmailInvitationResultDto(
    participationId: $checkedConvert(
      'participation_id',
      (v) => const IdConverter().fromJson(v as String),
    ),
    status: $checkedConvert('status', (v) => v as String?),
    skipped: $checkedConvert('skipped', (v) => v as String?),
    repeated: $checkedConvert('repeated', (v) => v as bool? ?? false),
  );
  return val;
}, fieldKeyMap: const {'participationId': 'participation_id'});

Map<String, dynamic> _$EmailInvitationResultDtoToJson(
  EmailInvitationResultDto instance,
) => <String, dynamic>{
  'participation_id': const IdConverter().toJson(instance.participationId),
  'status': instance.status,
  'skipped': instance.skipped,
  'repeated': instance.repeated,
};

EmailInvitationsResponse _$EmailInvitationsResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EmailInvitationsResponse', json, ($checkedConvert) {
  final val = EmailInvitationsResponse(
    results: $checkedConvert(
      'results',
      (v) => (v as List<dynamic>)
          .map(
            (e) => EmailInvitationResultDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$EmailInvitationsResponseToJson(
  EmailInvitationsResponse instance,
) => <String, dynamic>{
  'results': instance.results.map((e) => e.toJson()).toList(),
};
