/// Soar Score API handlers: shared shelf routing for the deployed API server
/// and the embedded Windows instance (pure Dart).
///
/// This library is the public API of the package; consumers should import
/// only `package:soar_score_api_handlers/soar_score_api_handlers.dart`.
library;

export 'auth/account_principal_resolver.dart';
export 'auth/bearer_auth.dart';
export 'auth/guest_session_auth.dart';
export 'auth/guest_session_cookie.dart';
export 'auth/participant_principal.dart';
export 'auth/principal.dart';
export 'auth/token_verifier.dart';
export 'auth/user_profile.dart';
export 'draw/delayed_draw_runner.dart';
export 'draw/isolate_draw_runner.dart';
export 'handler.dart';
export 'handlers/invitation_handlers.dart' show defaultSelfScoringBaseUrl;
export 'handlers/participant_handlers.dart';
export 'middleware/client_address.dart';
export 'middleware/failure_rate_limiter.dart';
export 'middleware/invitation_throttle.dart';
export 'middleware/middleware.dart';
