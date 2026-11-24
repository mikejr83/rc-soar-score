import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart'
    show LogFormat, configureLogging;
import 'package:soar_score_ui/soar_score_ui.dart';

import 'api_client_provider.dart';
import 'app.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_session_factory.dart';
import 'bundled_licences.dart';
import 'data/api_self_score_repository.dart';
import 'data/sample_self_score_repository.dart';
import 'data/self_score_repository.dart';
import 'data/self_score_scope.dart';
import 'session/api_http_client_stub.dart'
    if (dart.library.js_interop) 'session/api_http_client_web.dart';
import 'session/browser_storage_stub.dart'
    if (dart.library.js_interop) 'session/browser_storage_web.dart';
import 'session/guest_session_scope.dart';
import 'session/guest_session_store.dart';
import 'session/score_draft_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Warnings (a failed sign-in restore, say) go to the browser console.
  configureLogging(level: Level.INFO, format: LogFormat.text, sink: debugPrint);
  // Invitation links are plain paths, not `#/...` addresses.
  usePathUrlStrategy();
  registerBrandFontLicenses();
  registerProjectLicence();
  const String defaultUrl = 'http://localhost:8080';
  const String configuredUrl = String.fromEnvironment(
    'SOAR_SCORE_API_BASE_URL',
  );
  final baseUrl = configuredUrl.isEmpty ? defaultUrl : configuredUrl;
  // The guest session is an HttpOnly cookie the API sets, which the web client
  // sends with every request. `X-Requested-With` tells the API this is the
  // app, so it sets the cookie and accepts cookie-authenticated writes. A
  // body token (native, tests) is sent as a bearer token instead.
  final storage = openBrowserStorage();
  final sessions = StringSlotGuestSessionStore(
    KeyValueSlot(storage, 'soar_score_self_score.guest_session'),
  );
  // Sign-in state. `restore` also completes a sign-in redirect from Auth0, so
  // it runs before the first frame.
  final auth = createAuthSession();
  await auth.restore();
  final client = ApiClient(
    baseUrl: Uri.parse(baseUrl),
    httpClient: openApiHttpClient(),
    defaultHeaders: const {'X-Requested-With': 'soar-score-self-score'},
    tokenProvider: () async => sessions.read()?.token,
    // The account routes take the Auth0 access token; the participant routes
    // keep the guest token (a bearer there would take the place of the cookie).
    accountTokenProvider: auth.accessToken,
  );

  // Design review can still run on the sample contest:
  // `--dart-define=SOAR_SCORE_SAMPLE_DATA=true`.
  const useSampleData = bool.fromEnvironment('SOAR_SCORE_SAMPLE_DATA');
  final SelfScoreRepository repository = useSampleData
      ? const SampleSelfScoreRepository()
      : ApiSelfScoreRepository(client, sessions);

  runApp(
    AuthScope(
      session: auth,
      child: ApiClientInherited(
        client: client,
        child: GuestSessionScope(
          store: sessions,
          child: ScoreDraftScope(
            store: ScoreDraftStore(storage),
            child: SelfScoreScope(
              repository: repository,
              child: const SelfScoreApp(),
            ),
          ),
        ),
      ),
    ),
  );
}
