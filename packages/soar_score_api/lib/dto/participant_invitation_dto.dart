import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'participant_invitation_dto.g.dart';

/// Body of `POST /api/v1/self-scoring/invitations/resolve` (#465, #141).
///
/// The [credential] is the high-entropy secret from the invitation link or
/// QR code. It travels only in this body, never in a path or query, so it
/// stays out of access logs.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ResolveInvitationRequest {
  const ResolveInvitationRequest({required this.credential, this.deviceId});

  factory ResolveInvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$ResolveInvitationRequestFromJson(json);

  final String credential;

  /// A stable id the app generates once per device, recorded as the source
  /// device on every submission.
  final String? deviceId;

  Map<String, dynamic> toJson() => _$ResolveInvitationRequestToJson(this);
}

/// The contest a participant session is bound to, with only what a
/// participant may see.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ParticipantContestDto {
  const ParticipantContestDto({
    required this.contestId,
    required this.name,
    required this.disciplineType,
    required this.lifecycle,
    required this.scoringAccess,
    required this.roundCount,
    this.timeZone,
    this.publicResultsUrl,
  });

  factory ParticipantContestDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantContestDtoFromJson(json);

  final Id contestId;
  final String name;

  /// The discipline, for example `F5J`.
  final String disciplineType;

  /// The contest lifecycle: `Ready`, `Running` or `Completed`.
  final String lifecycle;

  /// Whether participants may submit now: `open`, `closed` or `read_only`.
  final String scoringAccess;
  final int roundCount;

  /// The contest's IANA time zone id.
  final String? timeZone;

  /// Where the contest is on the public site, or null when its results are
  /// not public.
  final String? publicResultsUrl;

  Map<String, dynamic> toJson() => _$ParticipantContestDtoToJson(this);
}

/// The participant link behind a session: who the guest is.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ParticipantLinkDto {
  const ParticipantLinkDto({
    required this.participationId,
    required this.pilotName,
    this.pilotNumber,
    required this.role,
    this.teamName,
  });

  factory ParticipantLinkDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantLinkDtoFromJson(json);

  /// The contest-scoped participant link id (never an account id or email).
  final Id participationId;
  final String pilotName;
  final int? pilotNumber;

  /// `pilot` in the first release; `helper` arrives with teams.
  final String role;
  final String? teamName;

  Map<String, dynamic> toJson() => _$ParticipantLinkDtoToJson(this);
}

/// The answer to resolving an invitation: a guest session plus the contest
/// and participant link it is bound to.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ResolveInvitationResponse {
  const ResolveInvitationResponse({
    required this.sessionToken,
    required this.sessionExpiresAt,
    required this.contest,
    required this.participant,
  });

  factory ResolveInvitationResponse.fromJson(Map<String, dynamic> json) =>
      _$ResolveInvitationResponseFromJson(json);

  /// The bearer token for every later participant call. The server still
  /// checks the invitation, lifecycle and scoring access on each use.
  final String sessionToken;
  final DateTime sessionExpiresAt;
  final ParticipantContestDto contest;
  final ParticipantLinkDto participant;

  Map<String, dynamic> toJson() => _$ResolveInvitationResponseToJson(this);
}
