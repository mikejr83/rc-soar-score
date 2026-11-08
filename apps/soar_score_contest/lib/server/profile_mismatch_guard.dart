import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

/// The error code of a request refused while the signed-in account is not the
/// one this computer's data belongs to.
const String profileAccountMismatchCode = 'profile_account_mismatch';

/// Refuses every request but `GET /health` while [mismatched] answers true.
///
/// The embedded API acts as the account the installation was claimed into. When
/// a different account signs in and the service refuses its claim, that data
/// is not theirs: reading it would show them another account's contests, and
/// writing would leave rows owned by the other account that can never sync.
/// The app clears the state when the director signs out or signs in as the
/// owning account.
Middleware profileMismatchGuard({required bool Function() mismatched}) =>
    (inner) => (request) {
      final isHealth = request.method == 'GET' && request.url.path == 'health';
      if (!isHealth && mismatched()) {
        return errorResponse(
          409,
          profileAccountMismatchCode,
          'This computer holds another account\'s data. Sign in as that '
          'account, or use a different Windows user.',
        );
      }
      return inner(request);
    };
