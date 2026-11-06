import 'package:equatable/equatable.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Request context key under which the guest session layer stores the
/// [ParticipantPrincipal].
const String participantPrincipalContextKey = 'soar_score.participant';

/// Who a participant request acts as: a guest opened through an invitation
/// link, for that one participation.
///
/// It is a different type, under a different context key, from the director
/// [Principal]: a participant route reads this one, and a director route
/// (`requirePrincipal`) never sees it, so a guest session can never act as a
/// director. It is rebuilt from the stored invitation on every request.
class ParticipantPrincipal extends Equatable {
  const ParticipantPrincipal(this.access);

  final ParticipantAccess access;

  Id get guestAccountId => access.guestAccountId;
  Id get contestId => access.contestId;
  Id get participationId => access.participationId;
  Id get invitationId => access.invitation.id;

  /// The metadata for a score the guest submits: authority Participant, the
  /// guest as the actor.
  MutationMetadata mutationMetadata({
    required String clientMutationId,
    required DateTime clientTime,
  }) => MutationMetadata(
    clientMutationId: clientMutationId,
    authority: Authority.participant,
    clientTime: clientTime,
    actorId: guestAccountId,
  );

  @override
  List<Object?> get props => [access];
}

/// The [ParticipantPrincipal] of [request], or null if the guest session
/// layer set none.
ParticipantPrincipal? participantPrincipalOf(Request request) =>
    request.context[participantPrincipalContextKey] as ParticipantPrincipal?;

/// The [ParticipantPrincipal] of [request].
///
/// Throws a [StateError] when none is set: participant routes sit behind
/// `guestSessionAuth`, so a missing one is a wiring mistake.
ParticipantPrincipal requireParticipant(Request request) =>
    participantPrincipalOf(request) ??
    (throw StateError(
      'No participant on the request: auth layer not applied.',
    ));
