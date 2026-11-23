import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'account_participation_dto.g.dart';

/// Where a linked participation stands for the pilot: `invited` (the contest
/// has not started running), `in_progress` or `completed`.
abstract final class AccountParticipationPhase {
  static const invited = 'invited';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
}

/// One contest a signed-in pilot reaches through a confirmed link
/// (`GET /api/v1/account/participations`, #545).
///
/// Carries what the pilot needs to recognize the contest and open it, and
/// nothing of the director: no director name, no email, no id of a director's
/// record besides the contest and participation the pilot opens.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
@UtcTimestampConverter()
class AccountParticipationDto {
  const AccountParticipationDto({
    required this.participationId,
    required this.contestId,
    required this.contestName,
    required this.startDateTime,
    required this.endDateTime,
    required this.startDate,
    required this.endDate,
    required this.timezone,
    required this.phase,
    required this.readOnly,
    this.host,
    this.city,
    this.state,
    this.country,
    this.publicResultsUrl,
  });

  factory AccountParticipationDto.fromJson(Map<String, dynamic> json) =>
      _$AccountParticipationDtoFromJson(json);

  final Id participationId;
  final Id contestId;
  final String contestName;
  final DateTime startDateTime;
  final DateTime endDateTime;

  /// The first and last day of the contest in its own time zone, as
  /// `YYYY-MM-DD`: what a pilot reads on the schedule, which the UTC
  /// timestamps above cannot give without the zone database.
  final String startDate;
  final String endDate;

  /// The contest's IANA time zone id.
  final String timezone;

  /// An [AccountParticipationPhase] value.
  final String phase;

  /// True in the 24 hours after the contest completed: the pilot can look,
  /// not submit.
  final bool readOnly;

  final String? host;
  final String? city;
  final String? state;
  final String? country;

  /// Where the contest's results are on the public site, or null when the
  /// contest is not published and public.
  final String? publicResultsUrl;

  Map<String, dynamic> toJson() => _$AccountParticipationDtoToJson(this);
}

/// Answer of `GET /api/v1/account/participations`: newest contest first.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class AccountParticipationsDto {
  const AccountParticipationsDto({this.participations = const []});

  factory AccountParticipationsDto.fromJson(Map<String, dynamic> json) =>
      _$AccountParticipationsDtoFromJson(json);

  final List<AccountParticipationDto> participations;

  Map<String, dynamic> toJson() => _$AccountParticipationsDtoToJson(this);
}

/// A contest that invited the profile behind a [LinkCandidateDto].
///
/// What the pilot needs to recognize the contest, and no owner or id of a
/// director's record.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@UtcTimestampConverter()
class LinkCandidateContestDto {
  const LinkCandidateContestDto({
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    required this.timezone,
    this.host,
    this.city,
    this.state,
    this.country,
  });

  factory LinkCandidateContestDto.fromJson(Map<String, dynamic> json) =>
      _$LinkCandidateContestDtoFromJson(json);

  final String name;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String timezone;
  final String? host;
  final String? city;
  final String? state;
  final String? country;

  Map<String, dynamic> toJson() => _$LinkCandidateContestDtoToJson(this);
}

/// A suggested "Is this you?" match (`GET /api/v1/account/link-candidates`).
///
/// The pilot name is as the director typed it. [id] is what the pilot answers
/// with (`confirm` or `decline`); it is the only id the card carries.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
@IdConverter()
class LinkCandidateDto {
  const LinkCandidateDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.contests = const [],
  });

  factory LinkCandidateDto.fromJson(Map<String, dynamic> json) =>
      _$LinkCandidateDtoFromJson(json);

  final Id id;
  final String firstName;
  final String lastName;
  final List<LinkCandidateContestDto> contests;

  Map<String, dynamic> toJson() => _$LinkCandidateDtoToJson(this);
}

/// Answer of `GET /api/v1/account/link-candidates`: empty unless the
/// account has a verified email that matches an invited pilot.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class LinkCandidatesDto {
  const LinkCandidatesDto({this.candidates = const []});

  factory LinkCandidatesDto.fromJson(Map<String, dynamic> json) =>
      _$LinkCandidatesDtoFromJson(json);

  final List<LinkCandidateDto> candidates;

  Map<String, dynamic> toJson() => _$LinkCandidatesDtoToJson(this);
}

/// One link between the signed-in account and a pilot's profile, as the
/// pilot sees and ends it (`/api/v1/account/links`).
///
/// [pilotName] is the profile's name as the director typed it. No email, no
/// director, no profile id.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
@UtcTimestampConverter()
class AccountLinkDto {
  const AccountLinkDto({
    required this.id,
    required this.pilotName,
    required this.status,
    required this.origin,
    this.confirmedAt,
    this.endedAt,
  });

  factory AccountLinkDto.fromJson(Map<String, dynamic> json) =>
      _$AccountLinkDtoFromJson(json);

  final Id id;
  final String pilotName;

  /// `Confirmed` or `Ended`.
  final ParticipantLinkStatus status;

  /// How the link arose: `EmailMatch`, `DirectoryPull` or
  /// `InvitationRedemption`.
  final ParticipantLinkOrigin origin;
  final DateTime? confirmedAt;
  final DateTime? endedAt;

  Map<String, dynamic> toJson() => _$AccountLinkDtoToJson(this);
}

/// Answer of `GET /api/v1/account/links`: the confirmed links, oldest first.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
  explicitToJson: true,
)
class AccountLinksDto {
  const AccountLinksDto({this.links = const []});

  factory AccountLinksDto.fromJson(Map<String, dynamic> json) =>
      _$AccountLinksDtoFromJson(json);

  final List<AccountLinkDto> links;

  Map<String, dynamic> toJson() => _$AccountLinksDtoToJson(this);
}
