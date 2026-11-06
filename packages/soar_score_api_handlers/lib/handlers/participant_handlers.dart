import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../auth/guest_session_auth.dart';
import '../auth/guest_session_cookie.dart';
import '../auth/participant_principal.dart';
import '../middleware/error_mapping.dart';
import '../middleware/failure_rate_limiter.dart';
import '../middleware/request_id.dart';
import 'health_handler.dart';
import 'participant_score_handlers.dart';
import 'participant_results_views.dart';
import 'participant_views.dart';
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
/// - `POST /session/end` removes the session cookie (204).
/// - `GET /session` is the session's own context, behind the guest session
///   layer: the call the app makes to check a stored session.
///
/// - `GET /overview` is the pilot's overview: their flight in every round,
///   its score state and the next round to score (a
///   [ParticipantOverviewDto]).
/// - `GET /rounds/{round}/entry` is the entry context of the pilot's flight
///   in round number `{round}` (a [ParticipantEntryContextDto]); 404
///   `not_found` for a round the pilot has no flight in.
/// - `GET /rounds/{round}/group-results` is the pilot's group in that round
///   (a [ParticipantGroupResultsDto]), calculated from official scores and
///   pilots' submitted attempts; 404 `not_found` like the entry route.
/// - `GET /results?round={n}` is the overall individual standings (a
///   [ParticipantOverallResultsDto]), held at the director's hidden-through
///   round while results are hidden; 404 `not_found` for a round without
///   scores. Pilot-entered scores are preliminary and appear only here and
///   in the group results, never in stored or published results.
///
/// Routes that read or change a pilot's data sit behind `guestSessionAuth`
/// too and read `requireParticipant`: they answer for the session's own
/// participation only, and take no pilot or contest id from the request. With [service] null
/// (a server without an invitation secret, or the embedded instance) every
/// route answers 409 `invitations_not_available`.
Handler buildParticipantHandler(
  Repository repository, {
  required InvitationService? service,
  FailureRateLimiter? limiter,
  Set<String> allowedOrigins = const {},
  DateTime Function()? clock,
}) {
  final now = clock ?? DateTime.now;
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
      final json = answer.toJson();
      // The web app (it sends X-Requested-With) keeps the session in a
      // cookie and never sees the token; other clients get it in the body.
      final web = (request.headers[webClientHeader] ?? '').isNotEmpty;
      if (web) json['session_token'] = null;
      return jsonResponse(json).change(
        headers: {
          'cache-control': 'no-store',
          if (web)
            'set-cookie': guestSessionSetCookie(
              resolution.sessionToken,
              resolution.sessionExpiresAt.difference(now()),
            ),
        },
      );
    } on InvitationAccessError {
      rateLimiter.recordFailure(key);
      rethrow;
    }
  });

  final session = Router()
    ..get('/session', (Request request) async {
      final access = requireParticipant(request).access;
      final context = await participantContext(repository, access);
      return jsonResponse({
        'contest': context.contest.toJson(),
        'participant': context.participant.toJson(),
      }).change(headers: {'cache-control': 'no-store'});
    })
    ..get('/overview', (Request request) async {
      final access = requireParticipant(request).access;
      final overview = await participantOverview(repository, access);
      return jsonResponse(overview.toJson())
          .change(headers: {'cache-control': 'no-store'});
    })
    ..get('/rounds/<round>/entry', (Request request, String round) async {
      final access = requireParticipant(request).access;
      final ordinal = int.tryParse(round);
      final entry = ordinal == null
          ? null
          : await participantEntryContext(repository, access, ordinal);
      if (entry == null) {
        return errorResponse(
          404,
          'not_found',
          'No such round.',
          requestId: requestIdOf(request),
        );
      }
      return jsonResponse(entry.toJson())
          .change(headers: {'cache-control': 'no-store'});
    });

  session
    ..get('/rounds/<round>/group-results', (
      Request request,
      String round,
    ) async {
      final access = requireParticipant(request).access;
      final ordinal = int.tryParse(round);
      final group = ordinal == null
          ? null
          : await participantGroupResults(repository, access, ordinal);
      if (group == null) {
        return errorResponse(
          404,
          'not_found',
          'No such round.',
          requestId: requestIdOf(request),
        );
      }
      return jsonResponse(group.toJson())
          .change(headers: {'cache-control': 'no-store'});
    })
    ..get('/results', (Request request) async {
      final access = requireParticipant(request).access;
      final param = request.url.queryParameters['round'];
      final asOf = param == null ? null : int.tryParse(param);
      final results = param != null && asOf == null
          ? null
          : await participantOverallResults(
              repository,
              access,
              asOfRound: asOf,
            );
      if (results == null) {
        return errorResponse(
          404,
          'not_found',
          'No results for that round.',
          requestId: requestIdOf(request),
        );
      }
      return jsonResponse(results.toJson())
          .change(headers: {'cache-control': 'no-store'});
    });

  addParticipantScoreRoutes(session, repository, clock: clock);

  // Ends the session in this browser: removes the cookie. Needs no valid
  // session (a dead cookie must be removable); a cookie write still has to
  // pass the same-site check.
  router.post('/session/end', (Request request) {
    final cookie = guestSessionFromCookieHeader(request.headers['cookie']);
    if (cookie != null) {
      final refusal = requireCookieWriteIsSameSite(request, allowedOrigins);
      if (refusal != null) return refusal;
    }
    return Response(
      204,
      headers: {
        'set-cookie': guestSessionClearCookie(),
        'cache-control': 'no-store',
      },
    );
  });

  router.mount(
    '/',
    service == null
        ? (Request request) => throw ContestStateError(
            'invitations_not_available',
            'this server does not issue invitations',
          )
        : guestSessionAuth(service, allowedOrigins: allowedOrigins)(
            session.call,
          ),
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
  final context = await participantContext(repository, resolution.access);
  return ResolveInvitationResponse(
    sessionToken: resolution.sessionToken,
    sessionExpiresAt: resolution.sessionExpiresAt,
    contest: context.contest,
    participant: context.participant,
  );
}
