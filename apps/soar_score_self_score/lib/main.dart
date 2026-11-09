import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'api_client_provider.dart';
import 'app.dart';
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

void main() {
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
  final client = ApiClient(
    baseUrl: Uri.parse(baseUrl),
    httpClient: openApiHttpClient(),
    defaultHeaders: const {'X-Requested-With': 'soar-score-self-score'},
    tokenProvider: () async => sessions.read()?.token,
  );

  // Design review can still run on the sample contest:
  // `--dart-define=SOAR_SCORE_SAMPLE_DATA=true`.
  const useSampleData = bool.fromEnvironment('SOAR_SCORE_SAMPLE_DATA');
  final SelfScoreRepository repository = useSampleData
      ? const SampleSelfScoreRepository()
      : ApiSelfScoreRepository(client, sessions);

  runApp(
    ApiClientInherited(
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
  );
}
