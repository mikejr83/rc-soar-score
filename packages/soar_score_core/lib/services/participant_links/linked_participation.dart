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

/// A suggested match for "Is this you?": a profile whose email equals the
/// signed-in account's verified email, and the contests that invited it.
///
/// Carries only what the pilot needs to recognize themselves: the name as
/// the director typed it and the contests. Never the director, the email or
/// any id of a director's record other than the profile id the pilot answers
/// with.
class LinkCandidate extends Equatable {
  const LinkCandidate({
    required this.profileId,
    required this.firstName,
    required this.lastName,
    required this.contests,
  });

  final Id profileId;
  final String firstName;
  final String lastName;

  /// The contests with an active invitation for this profile, by start.
  final List<CandidateContest> contests;

  @override
  List<Object?> get props => [profileId, firstName, lastName, contests];
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
