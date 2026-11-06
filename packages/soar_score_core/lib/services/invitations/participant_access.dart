import 'package:equatable/equatable.dart';

import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/invitation.dart';

/// What a verified guest session stands for: the one participation it was
/// opened on, checked against the stored invitation, participation and
/// contest at the time of the request.
class ParticipantAccess extends Equatable {
  const ParticipantAccess({
    required this.guestAccountId,
    required this.invitation,
    required this.participation,
    required this.contest,
    required this.readOnly,
  });

  /// The guest account that acts, and is recorded as the actor.
  final Id guestAccountId;

  /// The invitation the session was opened with; the access reference of
  /// every submission.
  final Invitation invitation;
  final ContestParticipation participation;
  final Contest contest;

  /// True in the 24 hours after the contest completes, when the participant
  /// may read the overview and results but not submit.
  final bool readOnly;

  Id get contestId => contest.id;
  Id get participationId => participation.id;

  @override
  List<Object?> get props => [
    guestAccountId,
    invitation,
    participation,
    contest,
    readOnly,
  ];
}

/// A signed-in guest opened a link: the session to keep, and what it opens.
class InvitationResolution {
  const InvitationResolution({
    required this.access,
    required this.sessionToken,
    required this.sessionExpiresAt,
  });

  final ParticipantAccess access;

  /// Sent back as the bearer token of participant requests. Long-lived: the
  /// service checks the invitation on every request, so replacing or
  /// revoking it ends the session.
  final String sessionToken;

  /// When the token stops working, at the latest.
  final DateTime sessionExpiresAt;
}

/// An invitation as issued: the stored row and the link's credential.
class IssuedInvitation {
  const IssuedInvitation({
    required this.invitation,
    required this.credential,
    required this.created,
  });

  final Invitation invitation;

  /// The raw credential for the link and QR code. Never log it.
  final String credential;

  /// False when the participation already had an active invitation (or the
  /// request was a retry), so the same link came back.
  final bool created;

  @override
  String toString() => 'IssuedInvitation(${invitation.id.value})';
}
