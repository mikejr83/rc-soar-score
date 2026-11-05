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
import 'session/browser_slot_stub.dart'
    if (dart.library.js_interop) 'session/browser_slot_web.dart';
import 'session/guest_session_scope.dart';

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
  // The guest session token goes with every request except resolving the
  // invitation link itself.
  final sessions = openGuestSessionStore();
  final client = ApiClient(
    baseUrl: Uri.parse(baseUrl),
    tokenProvider: () async => sessions.read()?.token,
  );

  // Design review can still run on the sample contest:
  // `--dart-define=SOAR_SCORE_SAMPLE_DATA=true`.
  const useSampleData = bool.fromEnvironment('SOAR_SCORE_SAMPLE_DATA');
  final SelfScoreRepository repository = useSampleData
      ? const SampleSelfScoreRepository()
      : ApiSelfScoreRepository(client);

  runApp(
    ApiClientInherited(
      client: client,
      child: GuestSessionScope(
        store: sessions,
        child: SelfScoreScope(
          repository: repository,
          child: const SelfScoreApp(),
        ),
      ),
    ),
  );
}
