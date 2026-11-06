import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'contest_invitations_dto.g.dart';

/// One participation's active invitation, as the director's cards and
/// copy-link need it.
///
/// The [link] is the stable link an emailed invitation carries too
/// (`https://score.rcsoarscore.com/invitations/{credential}`). It is a
/// secret in the sense that holding it opens the pilot's scoring page, so it
/// is for the director's eyes only and is never logged. The hash the server
/// stores is never sent.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ContestInvitationDto {
  const ContestInvitationDto({
    required this.participationId,
    required this.link,
  });

  factory ContestInvitationDto.fromJson(Map<String, dynamic> json) =>
      _$ContestInvitationDtoFromJson(json);

  final Id participationId;
  final String link;

  Map<String, dynamic> toJson() => _$ContestInvitationDtoToJson(this);
}

/// Answer of `GET /api/v1/contests/{id}/invitations`: who has an invitation,
/// and whether the contest may issue more now.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
@IdConverter()
class ContestInvitationsDto {
  const ContestInvitationsDto({
    required this.contestId,
    required this.canIssue,
    this.cannotIssueCode,
    this.cannotIssueReason,
    this.invitations = const [],
    this.unreproducibleParticipationIds = const [],
  });

  factory ContestInvitationsDto.fromJson(Map<String, dynamic> json) =>
      _$ContestInvitationsDtoFromJson(json);

  final Id contestId;

  /// False when the contest is not Configuring, Ready or Running.
  final bool canIssue;

  /// A stable code for why not (`invitations_not_issuable`), or null.
  final String? cannotIssueCode;

  /// The reason in words for the director, or null.
  final String? cannotIssueReason;

  /// The invitations that are active now, one per participation at most.
  final List<ContestInvitationDto> invitations;

  /// Participations whose active invitation cannot be shown as a link
  /// because the server's invitation secret changed after it was issued. A
  /// card for them cannot carry a working QR code.
  final List<Id> unreproducibleParticipationIds;

  Map<String, dynamic> toJson() => _$ContestInvitationsDtoToJson(this);
}

/// Body of `POST /api/v1/contests/{id}/invitations`: issue an invitation for
/// each listed participation that has none.
///
/// [requestId] makes a retry of the same request find what it issued. It
/// issues nothing by email.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class IssueInvitationsRequest {
  const IssueInvitationsRequest({
    required this.requestId,
    required this.participationIds,
  });

  factory IssueInvitationsRequest.fromJson(Map<String, dynamic> json) =>
      _$IssueInvitationsRequestFromJson(json);

  /// The most participations one request takes.
  static const int maxParticipations = 500;

  final String requestId;
  final List<Id> participationIds;

  Map<String, dynamic> toJson() => _$IssueInvitationsRequestToJson(this);
}

/// Answer of `POST /api/v1/contests/{id}/invitations`: how many were newly
/// issued, and every requested participation's invitation.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class IssueInvitationsResponse {
  const IssueInvitationsResponse({
    required this.issuedCount,
    required this.invitations,
  });

  factory IssueInvitationsResponse.fromJson(Map<String, dynamic> json) =>
      _$IssueInvitationsResponseFromJson(json);

  /// Invitations made by this request; 0 when all already existed.
  final int issuedCount;

  final List<ContestInvitationDto> invitations;

  Map<String, dynamic> toJson() => _$IssueInvitationsResponseToJson(this);
}
