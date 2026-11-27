import 'package:equatable/equatable.dart';

import '../../models/accounts/participant_account_link.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/invitation.dart';

/// A participation an account reaches through a Confirmed link: the pilot's
/// place in a contest whose invitation is active and still opens.
class LinkedParticipation extends Equatable {
  const LinkedParticipation({
    required this.link,
    required this.participation,
    required this.contest,
    required this.invitation,
    required this.readOnly,
  });

  final ParticipantAccountLink link;
  final ContestParticipation participation;
  final Contest contest;

  /// The active invitation that opens the participation.
  final Invitation invitation;

  /// True in the 24 hours after the contest completed.
  final bool readOnly;

  Id get participationId => participation.id;

  @override
  List<Object?> get props => [
    link,
    participation,
    contest,
    invitation,
    readOnly,
  ];
}

/// A finished contest in an account's history: the pilot's place in it,
/// reached through a Confirmed link. No invitation is needed.
class PastParticipation extends Equatable {
  const PastParticipation({
    required this.link,
    required this.participation,
    required this.contest,
  });

  final ParticipantAccountLink link;
  final ContestParticipation participation;
  final Contest contest;

  @override
  List<Object?> get props => [link, participation, contest];
}

/// A suggested match for "Is this you?": a profile whose email equals the
/// signed-in account's verified email, and the contests that invited it.
///
/// Carries only what the pilot needs to recognize themselves: the name as
/// the director typed it and the contests. Never the director, the email or
/// any id of a director's record: the pilot answers with [id], not the
/// profile id.
class LinkCandidate extends Equatable {
  const LinkCandidate({
    required this.id,
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.contests,
  });

  /// What the pilot answers with: derived from the account and the profile
  /// (see `InvitationCodec.candidateIdFor`), so it reveals no id of the
  /// director's records. Callers show this, never [profileId].
  final Id id;

  /// The director's profile. For the service and its callers on the server
  /// only; never sent to the pilot.
  final Id profileId;
  final String firstName;
  final String lastName;

  /// The contests with an active invitation for this profile, by start.
  final List<CandidateContest> contests;

  @override
  List<Object?> get props => [id, profileId, firstName, lastName, contests];
}

/// What a candidate shows of a contest: enough to recognize it, and nothing
/// that belongs to the director (no owner, no ids of the director's records).
class CandidateContest extends Equatable {
  const CandidateContest({
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    required this.timezone,
    this.host,
    this.city,
    this.state,
    this.country,
  });

  factory CandidateContest.of(Contest contest) => CandidateContest(
    name: contest.name,
    startDateTime: contest.startDateTime,
    endDateTime: contest.endDateTime,
    timezone: contest.timezone,
    host: contest.host,
    city: contest.city,
    state: contest.state,
    country: contest.country,
  );

  final String name;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String timezone;
  final String? host;
  final String? city;
  final String? state;
  final String? country;

  @override
  List<Object?> get props => [
    name,
    startDateTime,
    endDateTime,
    timezone,
    host,
    city,
    state,
    country,
  ];
}
