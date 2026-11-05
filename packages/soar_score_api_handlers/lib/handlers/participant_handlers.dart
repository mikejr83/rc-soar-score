import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../auth/guest_session_auth.dart';
import '../auth/participant_principal.dart';
import '../middleware/error_mapping.dart';
import '../middleware/failure_rate_limiter.dart';
import '../middleware/request_id.dart';
import 'health_handler.dart';
import 'request_body.dart';

final _logger = Logger('ParticipantHandlers');

/// The participant routes, served at `/api/v1/self-scoring`, outside the account sign-in with no account sign-in:
///
/// - `POST /invitations/resolve` with a [ResolveInvitationRequest] opens an
///   invitation link (the credential from
///   `https://score.rcsoarscore.com/invitations/{credential}`). It answers
///   a [ResolveInvitationResponse]: the guest session and the contest and
///   pilot the link is for.
///   Every link that does not open is the same 404 `invalid_invitation`;
///   too many failures from one address is a 429 `rate_limited`.
/// - `GET /session` is the session's own context, behind the guest session
///   layer: the call the app makes to check a stored session.
///
/// Routes that read or change a pilot's data (#787) sit behind
/// `guestSessionAuth` too and read `requireParticipant`. With [service] null
/// (a server without an invitation secret, or the embedded instance) every
/// route answers 409 `invitations_not_available`.
Handler buildParticipantHandler(
  Repository repository, {
  required InvitationService? service,
  FailureRateLimiter? limiter,
}) {
  final rateLimiter = limiter ?? FailureRateLimiter();
  final router = Router();

  InvitationService requireService() =>
      service ??
      (throw ContestStateError(
        'invitations_not_available',
        'this server does not issue invitations',
      ));

  router.post('/invitations/resolve', (Request request) async {
    final invitations = requireService();
    final key = clientKey(request);
    final wait = rateLimiter.blockedFor(key);
    if (wait != null) {
      _logger.warning('Too many failed invitation links from one address.');
      return errorResponse(
        429,
        'rate_limited',
        'Too many attempts. Try again later.',
        requestId: requestIdOf(request),
      ).change(headers: {'retry-after': '${wait.inSeconds + 1}'});
    }
    final body = await readJsonBody(request, ResolveInvitationRequest.fromJson);
    try {
      final resolution = await invitations.resolve(body.credential.trim());
      final answer = await _resolution(repository, resolution);
      return jsonResponse(answer.toJson())
          .change(headers: {'cache-control': 'no-store'});
    } on InvitationAccessError {
      rateLimiter.recordFailure(key);
      rethrow;
    }
  });

  final session = Router()
    ..get('/session', (Request request) async {
      final access = requireParticipant(request).access;
      final context = await _context(repository, access);
      return jsonResponse({
        'contest': context.contest.toJson(),
        'participant': context.participant.toJson(),
      }).change(headers: {'cache-control': 'no-store'});
    });

  router.mount(
    '/',
    service == null
        ? (Request request) => throw ContestStateError(
            'invitations_not_available',
            'this server does not issue invitations',
          )
        : guestSessionAuth(service)(session.call),
  );
  return router.call;
}

/// What identifies the caller for rate limiting: the address Fly's proxy
/// saw, which a client cannot set; one shared key where there is no proxy.
String clientKey(Request request) =>
    request.headers['fly-client-ip'] ?? 'unknown';

Future<ResolveInvitationResponse> _resolution(
  Repository repository,
  InvitationResolution resolution,
) async {
  final context = await _context(repository, resolution.access);
  return ResolveInvitationResponse(
    sessionToken: resolution.sessionToken,
    sessionExpiresAt: resolution.sessionExpiresAt,
    contest: context.contest,
    participant: context.participant,
  );
}

Future<({ParticipantContestDto contest, ParticipantLinkDto participant})>
_context(Repository repository, ParticipantAccess access) async {
  final profile = await repository.participantProfileRepository.findById(
    access.participation.participantProfileId,
  );
  final contest = access.contest;
  final revision = await repository.contestConfigurationRevisionRepository
      .latestForContest(contest.id);
  final disciplineProfile = revision == null
      ? null
      : await repository.disciplineProfileRepository.findById(
          revision.disciplineProfileId,
        );
  final matrix = await repository.matrixRevisionRepository.latestForContest(
    contest.id,
  );
  final rounds = matrix == null
      ? const <Round>[]
      : await repository.roundRepository.listForRevision(matrix.id);
  final scoring = access.readOnly
      ? 'read_only'
      : contest.scoringAccess == ScoringAccess.open &&
            contest.adminLock == AdminLock.unlocked
      ? 'open'
      : 'closed';
  return (
    contest: ParticipantContestDto(
      contestId: contest.id,
      name: contest.name,
      disciplineType: _disciplineText[disciplineProfile?.profile.type] ?? '',
      lifecycle: switch (contest.lifecycleState) {
        LifecycleState.completed => 'Completed',
        LifecycleState.running => 'Running',
        _ => 'Ready',
      },
      scoringAccess: scoring,
      roundCount: rounds.length,
      timeZone: contest.timezone,
    ),
    participant: ParticipantLinkDto(
      participationId: access.participation.id,
      pilotName: [
        profile?.firstName,
        profile?.lastName,
      ].whereType<String>().join(' '),
      pilotNumber: access.participation.participantNumber,
      role: 'pilot',
    ),
  );
}

const _disciplineText = {
  DisciplineType.ales: 'ALES',
  DisciplineType.thermalDuration: 'ThermalDuration',
  DisciplineType.f3j: 'F3J',
  DisciplineType.f5j: 'F5J',
  DisciplineType.f3l: 'F3L',
  DisciplineType.f3k: 'F3K',
};
