import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';
import 'package:soar_score_contest/platform/web_bootstrap.dart';

import '../auth/auth_session.dart';
import '../auth/auth_session_factory.dart';
import '../server/embedded_server.dart';
import '../services/sync/app_sync.dart';
import '../services/ui_account/ui_account.dart';
import 'acting_account.dart';
import 'acting_ui_account.dart';
import 'app_bootstrap.dart';
import 'auth_epoch.dart';
import 'local_account_claimer.dart';
import 'native_sync.dart';

final _logger = Logger('NativeBootstrap');

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
  NativeBootstrap._(
    this._server,
    this._remoteClient,
    this._auth,
    this.sync,
    this._claimer,
    this._epoch,
    this.localUiStore,
    this._acting,
  ) : _client = ApiClient(
        baseUrl: _server.baseUrl,
        tokenProvider: () async => _server.secret,
      );

  final EmbeddedServer _server;
  final ApiClient _client;
  final ApiClient _remoteClient;
  final AuthSession _auth;

  /// The sync engine, wired to the local database.
  final NativeSync sync;

  /// Links the Local account to the signed-in one.
  final LocalAccountClaimer _claimer;

  /// Binds requests to sign-ins; closing it refuses the ones still waiting.
  final AuthEpoch _epoch;

  @override
  final LocalUiStore localUiStore;

  final ActingAccount _acting;

  @override
  late final UiAccount uiAccount = ActingUiAccount(_acting);

  bool _closed = false;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _remoteClient;

  @override
  AppSync get appSync => sync.appSync;

  @override
  void remoteReachabilityChanged({required bool reachable}) {
    sync.remoteReachabilityChanged(reachable: reachable);
    if (reachable) _claimer.connectivityRestored();
  }

  @override
  AuthSession get authSession => _auth;

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _logger.fine('Closing native bootstrap');
    _closed = true;
    _claimer.stop();
    _epoch.close();
    await sync.close();
    await _server.close();
    await localUiStore.close();
    (uiAccount as ActingUiAccount).dispose();
    _remoteClient.close();
  }

  /// Local database file for the native build: `soar_score.db` inside the
  /// per-user application-support directory
  /// (`%APPDATA%\<organization>\<app>` on Windows, the Roaming profile,
  /// resolved per-user by `path_provider`). Demo mode uses `soar_score_demo.db`
  /// beside it instead, so the real database is never touched.
  static Future<String> databasePath({bool demo = false}) async {
    final directory = await getApplicationSupportDirectory();
    _logger.finer('Using application support directory: ${directory.path}');
    return p.join(
      directory.path,
      demo ? demoDatabaseName : standardDatabaseName,
    );
  }

  static const String standardDatabaseName = 'soar_score.db';
  static const String demoDatabaseName = 'soar_score_demo.db';

  /// Whether to run on the demo database, which holds example data: only when
  /// built with `--dart-define=SOAR_SCORE_DEMO=true`, and never in a release
  /// build.
  static const bool demo =
      bool.fromEnvironment('SOAR_SCORE_DEMO') && !kReleaseMode;

  /// Whether demo mode starts from a new demo database, deleting the old one:
  /// `--dart-define=SOAR_SCORE_DEMO_RESET=true`.
  static const bool demoReset =
      demo && bool.fromEnvironment('SOAR_SCORE_DEMO_RESET');

  /// Starts the embedded API server and returns the client for it.
  static Future<AppBootstrap> start() async {
    const String rawUrl = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');
    final baseUrl = Uri.parse(rawUrl.isEmpty ? defaultApiBaseUrl : rawUrl);
    _logger.info('Base URL: $baseUrl');
    final database = await databasePath(demo: demo);
    if (demoReset) {
      _logger.info('Resetting demo database');
      await deleteDatabaseFiles(database);
    }
    final server = await startEmbeddedServer(database, seedDemo: demo);
    _logger.info('Embedded API server listening on ${server.baseUrl}');
    if (demo) {
      _logger.info('DEMO MODE: using the example database at $database');
    }
    // The embedded client carries the server's per-launch secret; only the
    // remote client carries the sign-in token.
    final auth = createAuthSession();
    await auth.restore();
    // Requests the app binds to a sign-in carry that sign-in's token or are
    // not sent (see AuthEpoch).
    final epoch = AuthEpoch(auth);
    final acting = ActingAccount(server, epoch);
    final remote = ApiClient(
      baseUrl: baseUrl,
      tokenProvider: epoch.boundToken(auth.accessToken),
    );
    final sync = await NativeSync.start(
      database: server.database,
      localAccountId: server.localAccountId,
      acting: acting,
      remote: remote,
      databasePath: database,
    );
    final claimer = LocalAccountClaimer(
      auth: auth,
      epoch: epoch,
      local: LocalAccountRepository(server.database),
      claim: remote.claimLocalAccount,
      onClaimed: (accountId, session) async {
        // New offline data is the account's from now on and syncs at once,
        // but only if the sign-in the claim was made under is still the one.
        if (!acting.actAs(accountId, epoch: session)) return;
        await sync.accountClaimed(accountId);
      },
      onSignedOut: acting.actAsLocal,
      onProblem: sync.appSync.claimProblemChanged,
    )..start();
    // UI state has its own file beside the contest database, so resetting or
    // replacing contest data never clears it.
    final uiStore = await openLocalUiStore(directory: p.dirname(database));
    return NativeBootstrap._(
      server,
      remote,
      auth,
      sync,
      claimer,
      epoch,
      uiStore,
      acting,
    );
  }

  /// Deletes the SQLite file at [path] and its journal files, if present.
  static Future<void> deleteDatabaseFiles(String path) async {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}

/// Platform entry point shared by both bootstrap branches (see
/// `main.dart`'s conditional import).
Future<AppBootstrap> start() => NativeBootstrap.start();

void quitApplication() => exit(0);
