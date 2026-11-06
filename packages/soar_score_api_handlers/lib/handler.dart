import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/handlers.dart';
import 'package:soar_score_api_handlers/middleware/failure_rate_limiter.dart';
import 'package:soar_score_api_handlers/middleware/middleware.dart';
import 'package:soar_score_core/repositories/repository.dart';
import 'package:soar_score_core/services/invitations/invitation_service.dart';
import 'package:soar_score_core/services/recalculation/recalculation_service.dart';
import 'package:soar_score_core/services/sync/sync_versions.dart';
import 'package:soar_score_core/import/glider_score_import_runner.dart';
import 'package:soar_score_core/services/matrix/draw_job.dart';
import 'package:logging/logging.dart';

/// Auth layer for the `/api/v1` subtree.
///
/// Receives the unauthenticated `/api/v1` handler and returns a replacement
/// with authentication applied (e.g. the Auth0 JWT middleware from ticket
/// 010). It sets the request's `Principal` (see `auth/principal.dart`); the
/// embedded offline instance (ticket 018) never adds a token requirement and
/// uses `fixedPrincipal` with its Local account instead. When no middleware
/// is provided, the `/api/v1` routes stay unauthenticated and have no
/// principal.
typedef AuthMiddleware = Handler Function(Handler);

final _logger = Logger('Handler');

/// Builds the API's top-level shelf [Handler].
///
/// Every route runs inside the common middleware (request id, request
/// logging, JSON error mapping), see `middleware/middleware.dart`.
///
/// Served routes:
/// - `GET /health` — public health payload.
/// - `GET /robots.txt` — disallows all crawlers.
/// - `GET /api/v1/meta` — placeholder identifying the API.
/// - `GET /api/v1/ping` — placeholder liveness probe.
///
/// [contests] is the [ContestRepository] the API will be wired against; the
/// caller chooses the data store (PostgreSQL for the deployed server,
/// SQLite for the embedded Windows instance per ticket 018). The current
/// placeholder routes do not execute queries yet; business routes added in
/// later tickets will read through it.
///
/// The serving identity ([name], [displayName], [version]) is supplied by
/// the caller so the deployed server and the embedded instance report
/// themselves distinctly while sharing the same routing code.
///
/// [authMiddleware], when provided, wraps only the `/api/v1` subtree;
/// `GET /health` always stays public (ticket 010 carve-out).
///
/// [publishingEnabled] turns on the publication routes and the public reads
/// at `/public`, which need no sign-in. Only the hosted
/// server sets it; without it they answer 409 `publishing_not_available`.
///
/// [gliderScoreImport], when provided, makes the native Windows instance
/// serve `POST /imports/gliderscore`; without it the route answers 503
/// `import_unavailable`. Only the embedded instance wires it.
///
/// [drawRunner] is where matrix draws run: an isolate of their own by
/// default, so a long draw never stops the API from answering. Tests and the
/// E2E servers pass another runner.
///
/// [invitations], when provided, turns on the participant routes at
/// `/api/v1/self-scoring` (opening an invitation link and the guest session); they
/// need no account sign-in and sit outside [authMiddleware]. Without it they
/// answer 409 `invitations_not_available`. [invitationRateLimiter] replaces
/// the default limit on failed link attempts (tests).
///
/// [corsAllowedOrigins] are the exact browser origins (for example
/// `http://127.0.0.1:8091`) allowed to call the API cross-origin. Empty, the
/// default, adds no CORS headers.
Handler buildApiHandler({
  required String name,
  required String displayName,
  required String version,
  int? schemaRevision,
  required Repository repository,
  AuthMiddleware? authMiddleware,
  bool publishingEnabled = false,
  RecalculationService? recalculation,
  GliderScoreImportRunner? gliderScoreImport,
  DrawRunner? drawRunner,
  Set<String> corsAllowedOrigins = const {},
  InvitationService? invitations,
  FailureRateLimiter? invitationRateLimiter,
}) {
  final handlers = createHandlers(
    name,
    displayName,
    version,
    repository,
    publishingEnabled: publishingEnabled,
    recalculation: recalculation,
    syncVersions: SyncVersions.exactly(schemaRevision ?? 1),
    gliderScoreImport: gliderScoreImport,
    drawRunner: drawRunner,
    invitations: invitations,
    invitationRateLimiter: invitationRateLimiter,
    corsAllowedOrigins: corsAllowedOrigins,
  );
  Handler api = handlers.apiHandler;

  if (authMiddleware != null) {
    api = authMiddleware(api);
    _logger.fine('Auth middleware applied to /api/v1 subtree.');
  } else {
    _logger.fine('No auth middleware applied to /api/v1 subtree.');
  }

  final app = Router()
    ..get('/robots.txt', robotsTxtHandler)
    ..mount('/', handlers.healthHandler)
    // Before `/api/v1`, so these routes keep the DTO paths but answer to
    // their own guest session instead of the account sign-in.
    ..mount('/api/v1/self-scoring', handlers.participantHandler)
    ..mount('/api/v1', api)
    ..mount('/public', handlers.publicHandler);

  _logger.fine('API handler built successfully.');

  return withCommonMiddleware(app.call, corsAllowedOrigins: corsAllowedOrigins);
}
