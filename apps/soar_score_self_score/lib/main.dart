import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';

import 'api_client_provider.dart';
import 'app.dart';

void main() {
  const String defaultUrl = 'http://localhost:8080';
  const String configuredUrl = String.fromEnvironment(
    'SOAR_SCORE_API_BASE_URL',
  );
  final baseUrl = configuredUrl.isEmpty ? defaultUrl : configuredUrl;
  final client = ApiClient(baseUrl: Uri.parse(baseUrl));

  runApp(ApiClientInherited(client: client, child: const SelfScoreApp()));
}
