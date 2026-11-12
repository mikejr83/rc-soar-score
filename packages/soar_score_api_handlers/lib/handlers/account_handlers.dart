import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';

/// Adds the account identity route to [router] (mounted under `/api/v1`):
///
/// - `GET /account` answers the id of the account the caller acts as
///   (`account_id`), the id the audit trail records as the actor of what the
///   caller does. A client's own sign-in identity (an identity-provider
///   subject) is not that id, so a client that must recognise its own audit
///   events asks here.
void addAccountRoutes(Router router) {
  router.get('/account', (Request request) {
    final principal = requirePrincipal(request);
    return jsonResponse(<String, dynamic>{
      'account_id': principal.accountId.value,
    });
  });
}
