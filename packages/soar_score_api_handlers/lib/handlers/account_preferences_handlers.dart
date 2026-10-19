import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the account preference routes to [router] (mounted under `/api/v1`):
///
/// - `GET /account/preferences` answers the caller's preferred time zone and
///   locale, each null until chosen
/// - `PUT /account/preferences` replaces them; a null field clears that choice
///
/// An unknown IANA zone id or an unsupported locale answers 400. The hosted
/// server only: the embedded instance has no accounts and answers 409
/// `backend_only`.
void addAccountPreferencesRoutes(Router router, Repository repository) {
  final service = AccountPreferencesService(repository);

  router.get('/account/preferences', (Request request) async {
    final principal = requirePrincipal(request);
    return jsonResponse((await service.get(principal.accountId)).toJson());
  });

  router.put('/account/preferences', (Request request) async {
    final principal = requirePrincipal(request);
    final preferences = await readJsonBody(
      request,
      AccountPreferences.fromJson,
    );
    final saved = await service.update(
      accountId: principal.accountId,
      preferences: preferences,
      now: DateTime.now().toUtc(),
    );
    return jsonResponse(saved.toJson());
  });
}
