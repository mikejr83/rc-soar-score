import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart'
    show DelayedDrawRunner, IsolateDrawRunner;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';
import 'package:soar_score_contest/platform/web_bootstrap.dart';

import '../auth/auth_session.dart';
import '../auth/auth_session_factory.dart';
import '../server/embedded_server.dart';
import '../server/profile_access.dart';
import '../services/sync/sync_problem.dart';
import '../services/exchange/contest_exchange.dart';
import '../services/competition_import/competition_import.dart';
import '../services/pilot_import/pilot_import.dart';
import '../services/sync/app_sync.dart';
import '../services/ui_account/ui_account.dart';
import 'acting_account.dart';
import 'acting_ui_account.dart';
import 'app_bootstrap.dart';
import 'auth_epoch.dart';
import 'local_account_claimer.dart';
import 'native_contest_exchange.dart';
import 'native_competition_import_store.dart';
import 'native_preferences.dart';
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
    this._preferences,
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

  /// The account's preferences, read and kept here.
  final NativePreferences _preferences;

  @override
  late final UiAccount uiAccount = ActingUiAccount(_acting);

  bool _closed = false;

  @override
  ApiClient get apiClient => _client;

  @override
  ApiClient get remoteApiClient => _remoteClient;

  @override
  ApiClient get publicationApiClient => _remoteClient;

  @override
  AppSync get appSync => sync.appSync;

  @override
  void remoteReachabilityChanged({required bool reachable}) {
    sync.remoteReachabilityChanged(reachable: reachable);
    if (reachable) _claimer.connectivityRestored();
  }

  @override
  Stream<bool> get syncReachability => sync.reachability;

  @override
  void syncFocusChanged(String? contestId) => sync.focusChanged(contestId);

  @override
  void appActiveChanged({required bool active}) =>
      sync.appActiveChanged(active: active);

  @override
  bool get hasLocalStorage => true;

  @override
  Future<void> checkStorage() =>
      LocalAccountRepository(_server.database).preferences();

  @override
  AuthSession get authSession => _auth;

  @override
  Future<core.AccountPreferences> loadPreferences() => _preferences.load();

  @override
  Future<void> savePreferences(core.AccountPreferences preferences) =>
      _preferences.save(preferences);

  @override
  Stream<void> get preferencesChanged => _preferences.changes;

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _logger.fine('Closing native bootstrap');
    _closed = true;
    ContestExchange.current = null;
    PilotImportStore.current = null;
    CompetitionImportStore.current = null;
    _claimer.stop();
    await _preferences.close();
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
  /// resolved per-user by `path_provider`). A non-release build can override
  /// the directory with `--dart-define=SOAR_SCORE_LOCAL_DATA_DIRECTORY=<path>`.
  /// Demo mode uses `soar_score_demo.db` beside it instead, so the real
  /// database is never touched.
  static Future<String> databasePath({
    bool demo = false,
    String? localDataDirectory,
  }) async {
    final configuredDirectory =
        localDataDirectory ?? _localDataDirectoryFromEnvironment;
    final directory = configuredDirectory.isNotEmpty && !kReleaseMode
        ? Directory(configuredDirectory)
        : await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final database = p.join(
      directory.path,
      demo ? demoDatabaseName : standardDatabaseName,
    );
    _logger.info('Using local database: $database');
    return database;
  }

  static const String standardDatabaseName = 'soar_score.db';
  static const String demoDatabaseName = 'soar_score_demo.db';

  static const String _localDataDirectoryFromEnvironment =
      String.fromEnvironment('SOAR_SCORE_LOCAL_DATA_DIRECTORY');

  /// Whether to run on the demo database, which holds example data: only when
  /// built with `--dart-define=SOAR_SCORE_DEMO=true`, and never in a release
  /// build.
  static const bool demo =
      bool.fromEnvironment('SOAR_SCORE_DEMO') && !kReleaseMode;

  /// Whether demo mode starts from a new demo database, deleting the old one:
  /// `--dart-define=SOAR_SCORE_DEMO_RESET=true`.
  static const bool demoReset =
      demo && bool.fromEnvironment('SOAR_SCORE_DEMO_RESET');

  /// Whether matrix draws are held for a few seconds, so an end-to-end
  /// journey can see their progress and cancel one:
  /// `--dart-define=SOAR_SCORE_E2E_SLOW_DRAW=true`, demo builds only.
  static const bool slowDraws =
      demo && bool.fromEnvironment('SOAR_SCORE_E2E_SLOW_DRAW');

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
    final server = await startEmbeddedServer(
      database,
      seedDemo: demo,
      drawRunner: slowDraws
          ? const DelayedDrawRunner(IsolateDrawRunner())
          : null,
    );
    _logger.info('Embedded API server listening on ${server.baseUrl}');
    ContestExchange.current = NativeContestExchange(server);
    final importStore = NativeCompetitionImportStore(server);
    PilotImportStore.current = importStore;
    CompetitionImportStore.current = importStore;
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
      inspectionOwners: server.inspectionOwners,
    );
    final preferences = NativePreferences(
      epoch: epoch,
      local: LocalAccountRepository(server.database),
      put: remote.updateAccountPreferences,
    );
    final claimer = LocalAccountClaimer(
      auth: auth,
      epoch: epoch,
      local: LocalAccountRepository(server.database),
      claim: remote.claimLocalAccount,
      onSignedIn: acting.signedIn,
      onClaimStarting: acting.claimStarting,
      onClaimRecorded: acting.claimRecorded,
      onClaimFinished: acting.claimFinished,
      onClaimPostponed: () {
        if (acting.profileAccess == ProfileAccess.unverified) {
          sync.appSync.claimProblemChanged(SyncProblem.accountUnverified);
        }
      },
      onClaimed: (accountId, session) async {
        // New offline data is the account's from now on and syncs at once,
        // but only if the sign-in the claim was made under is still the one.
        if (!acting.actAs(accountId, epoch: session)) return;
        await sync.accountClaimed(accountId);
      },
      onSignedOut: acting.actAsLocal,
      onProblem: sync.appSync.claimProblemChanged,
      onAccountMismatch: (session) =>
          acting.markProfileMismatch(epoch: session),
      getPreferences: remote.getAccountPreferences,
      putPreferences: remote.updateAccountPreferences,
      onPreferencesChanged: preferences.changed,
    )..start();
    // UI state has its own file beside the contest database, so resetting or
    // replacing contest data never clears it.
    if (demoReset) {
      // A fresh demo starts without the last run's drafts and preferences.
      await deleteDatabaseFiles(
        p.join(p.dirname(database), 'soar_score_ui.db'),
      );
    }
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
      preferences,
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
