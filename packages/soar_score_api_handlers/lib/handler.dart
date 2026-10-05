import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/handlers/handlers.dart';
import 'package:soar_score_api_handlers/middleware/middleware.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:logging/logging.dart';

/// Auth layer for the `/api/v1` subtree.
///
/// Receives the unauthenticated `/api/v1` handler and returns a replacement
/// with authentication applied (e.g. the Auth0 JWT middleware from ticket
/// 010). When no middleware is provided, the `/api/v1` routes stay
/// unauthenticated — the embedded offline instance (ticket 018) deliberately
/// never adds a token requirement.
typedef AuthMiddleware = Handler Function(Handler);

final _logger = Logger('Handler');

/// Builds the API's top-level shelf [Handler].
///
/// Every route runs inside the common middleware (request id, request
/// logging, JSON error mapping), see `middleware/middleware.dart`.
///
/// Served routes:
/// - `GET /health` — public health payload.
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
Handler buildApiHandler({
  required String name,
  required String displayName,
  required String version,
  int? schemaRevision,
  required Repository repository,
  AuthMiddleware? authMiddleware,
}) {
  final handlers = createHandlers(name, displayName, version, repository);
  Handler api = handlers.apiHandler;

  if (authMiddleware != null) {
    api = authMiddleware(api);
    _logger.fine('Auth middleware applied to /api/v1 subtree.');
  } else {
    _logger.fine('No auth middleware applied to /api/v1 subtree.');
  }

  final app = Router()
    ..mount('/', handlers.healthHandler)
    ..mount('/api/v1', api);

  _logger.fine('API handler built successfully.');

  return withCommonMiddleware(app.call);
}
