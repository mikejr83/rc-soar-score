import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

import 'profile_access.dart';

/// Refuses every request but `GET /health` while [access] is not
/// [ProfileAccess.verified].
///
/// The embedded API acts as the account the installation was claimed into.
/// While a different (or unchecked) account is signed in, that data is not
/// theirs: reading it would show them another account's contests, and writing
/// would leave rows owned by the other account that can never sync. The app
/// ends the state when the director signs out, signs in as the owning
/// account, or the service says the claim is theirs.
Middleware profileMismatchGuard({required ProfileAccess Function() access}) =>
    (inner) => (request) {
      final isHealth = request.method == 'GET' && request.url.path == 'health';
      final state = access();
      if (!isHealth && state != ProfileAccess.verified) {
        return errorResponse(409, state.errorCode, state.message);
      }
      return inner(request);
    };
