import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import 'api_client_provider.dart';
import 'app.dart';
import 'bundled_licences.dart';
import 'data/sample_self_score_repository.dart';
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
  final client = ApiClient(baseUrl: Uri.parse(baseUrl));

  // The sample repository stands in until the API-backed one exists.
  runApp(
    ApiClientInherited(
      client: client,
      child: GuestSessionScope(
        store: openGuestSessionStore(),
        child: const SelfScoreScope(
          repository: SampleSelfScoreRepository(),
          child: SelfScoreApp(),
        ),
      ),
    ),
  );
}
