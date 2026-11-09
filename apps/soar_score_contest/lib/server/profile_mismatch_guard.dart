import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

import 'profile_access.dart';

/// Runs every request but `GET /health` as one operation on the claimed
/// profile ([runOperation], `EmbeddedServer.runProfileOperation`).
///
/// The embedded API acts as the account the installation was claimed into.
/// While a different (or unchecked) account is signed in, that data is not
/// theirs: reading it would show them another account's contests, and writing
/// would leave rows owned by the other account that can never sync. A request
/// is refused (409) when the profile is not open to the signed-in user, and is
/// stopped, with nothing stored, when it changes while the request runs (the
/// database refuses its writes and commit, and its answer is replaced). The
/// app ends the state when the director signs out, signs in as the owning
/// account, or the service says the claim is theirs.
Middleware profileMismatchGuard({
  required Future<Response> Function(Future<Response> Function() body)
  runOperation,
}) =>
    (inner) => (request) async {
      final isHealth = request.method == 'GET' && request.url.path == 'health';
      if (isHealth) return inner(request);
      try {
        return await runOperation(() async => inner(request));
      } on ProfileUnavailableError catch (error) {
        return errorResponse(409, error.errorCode, error.message);
      }
    };
