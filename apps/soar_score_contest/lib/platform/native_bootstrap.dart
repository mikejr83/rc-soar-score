import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/web_bootstrap.dart';

import '../server/embedded_server.dart';
import 'app_bootstrap.dart';

/// Native (non-web) bootstrap, ticket 018: starts the in-process API server
/// on `localhost` backed by the app's local SQLite database, then exposes an
/// `ApiClient` pointed at that local instance — the same client code the web
/// build uses, pointed at a different server.
///
/// Selected for native builds only: `main.dart`'s conditional import falls
/// back to this file everywhere except web, so the FFI-backed data layer and
/// `dart:io` never enter the web compile closure. On Windows this is what the
/// fully disconnected offline application described in
/// `plan/architecture-requirements/offline-usage.md` boots.
class NativeBootstrap extends AppBootstrap {
  NativeBootstrap._(this._server, this._remoteClient)
    : _client = ApiClient(baseUrl: _server.baseUrl);

  final EmbeddedServer _server;
  final ApiClient _client;
  final ApiClient _remoteClient;

  bool _closed = false;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _remoteClient;

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _server.close();
    _remoteClient.close();
  }

  /// Local database file for the native build: `soar_score.db` inside the
  /// per-user application-support directory
  /// (`%APPDATA%\<organization>\<app>` on Windows, the Roaming profile,
  /// resolved per-user by `path_provider`).
  static Future<String> databasePath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'soar_score.db');
  }

  /// Starts the embedded API server and returns the client for it.
  static Future<AppBootstrap> start() async {
    const String rawUrl = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');
    final baseUrl = Uri.parse(rawUrl.isEmpty ? defaultApiBaseUrl : rawUrl);
    final database = await databasePath();
    final server = await startEmbeddedServer(database);
    debugPrint('Embedded API server listening on ${server.baseUrl}');
    return NativeBootstrap._(server, ApiClient(baseUrl: baseUrl));
  }
}

/// Platform entry point shared by both bootstrap branches (see
/// `main.dart`'s conditional import).
Future<AppBootstrap> start() => NativeBootstrap.start();
