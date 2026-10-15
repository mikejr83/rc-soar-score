import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the GliderScore import route to [router] (mounted under `/api/v1`):
///
/// - `POST /imports/gliderscore` reads the user's `.mdb` through
///   [gliderScoreImport] and answers with the table snapshot the wizard
///   reviews
///
/// Only the native Windows instance wires a runner into
/// [createHandlers]; the hosted server and the web build omit it and get a
/// 503 `import_unavailable` for the route, so its absence never takes the
/// server down.
void addImportRoutes(
  Router router,
  GliderScoreImportRunner? gliderScoreImport,
) {
  router.post('/imports/gliderscore', (Request request) async {
    requirePrincipal(request);
    if (gliderScoreImport == null) {
      throw ImportUnavailableError(
        'GliderScore import is unavailable on this server',
      );
    }
    final body = await readJsonBody(request, ImportGliderscoreRequest.fromJson);
    final result = await GliderScoreImportService().importFile(
      gliderScoreImport,
      dbPath: body.path,
      tables: body.tables?.toSet(),
    );
    return jsonResponse(result.toJson(), statusCode: 201);
  });
}
