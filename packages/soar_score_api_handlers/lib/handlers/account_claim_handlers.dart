import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/auth/principal.dart';
import 'package:soar_score_api_handlers/handlers/health_handler.dart';
import 'package:soar_score_api_handlers/handlers/request_body.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// Adds the account routes to [router] (which is mounted under `/api/v1`):
///
/// - `POST /account/local-claims` claims an installation's Local account into
///   the caller's account
///
/// A repeated claim by the same account answers 200 like the first. A Local
/// account that another account claimed answers 409 `already_claimed`; the id
/// of an existing account answers 400. The hosted server only: the embedded
/// instance has no accounts and answers 409 `backend_only`.
void addAccountClaimRoutes(Router router, Repository repository) {
  final service = AccountClaimsService(repository);

  router.post('/account/local-claims', (Request request) async {
    final principal = requirePrincipal(request);
    final body = await readJsonBody(request, ClaimLocalAccountRequest.fromJson);
    final alias = await service.claimLocalAccount(
      accountId: principal.accountId,
      localAccountId: body.localAccountId,
      now: DateTime.now().toUtc(),
    );
    return jsonResponse(
      LocalAccountClaimDto(
        accountId: principal.accountId,
        localAccountId: alias.id,
        claimedAt: alias.claimedAt,
      ).toJson(),
    );
  });
}
