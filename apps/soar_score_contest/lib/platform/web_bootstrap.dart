import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';

import '../auth/auth_session.dart';
import '../auth/auth_session_factory.dart';
import 'app_bootstrap.dart';

final _logger = Logger('WebBootstrap');

/// Base URL of the deployed `soar_score_server` for web builds.
///
/// The deployment location is not fixed yet, so the URL is supplied at build
/// time: `flutter build web --dart-define=SOAR_SCORE_API_BASE_URL=...`.
/// The default is the local development server (`dart run lib/main.dart`
/// binds `localhost:8080`), so an unmodified web build talks to a locally
/// running deployed server.
const String defaultApiBaseUrl = 'http://localhost:8080';

/// Web bootstrap: no embedded server — the browser build talks to the
/// deployed `soar_score_server` over HTTP. `close()` only releases the
/// `ApiClient`; everything else the native bootstrap does (server, SQLite)
/// is compiled out of the web artifact entirely.
class WebBootstrap extends AppBootstrap {
  WebBootstrap(this._client, this._auth);

  final ApiClient _client;
  final AuthSession _auth;
  bool _closed = false;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _client;

  @override
  AuthSession get authSession => _auth;

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _client.close();
  }

  /// Builds the client pointed at the deployed API.
  static Future<AppBootstrap> start() async {
    _logger.info("Starting web bootstrap");
    const String rawUrl = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');
    final baseUrl = Uri.parse(rawUrl.isEmpty ? defaultApiBaseUrl : rawUrl);
    _logger.info("Base URL: $baseUrl");
    // Completes a sign-in redirect (or restores the stored session) before
    // the first frame, so the router starts with the right signed-in state.
    final auth = createAuthSession();
    await auth.restore();
    return WebBootstrap(
      ApiClient(baseUrl: baseUrl, tokenProvider: auth.accessToken),
      auth,
    );
  }
}

/// Platform entry point shared by both bootstrap branches (see
/// `main.dart`'s conditional import).
Future<AppBootstrap> start() => WebBootstrap.start();

void quitApplication() {}
