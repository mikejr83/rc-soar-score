import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';

import 'api_client_provider.dart';
import 'app.dart';

/// Server base URL, set at build time with `--dart-define=SOAR_SCORE_API_BASE_URL=...`.
const String apiBaseUrl = String.fromEnvironment(
  'SOAR_SCORE_API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

void main() {
  runApp(
    ApiClientInherited(
      client: ApiClient(baseUrl: Uri.parse(apiBaseUrl)),
      child: const SoarScorePublicApp(),
    ),
  );
}
