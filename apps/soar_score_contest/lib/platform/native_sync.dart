import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

import 'engine_app_sync.dart';
import 'installation_id_file.dart';

final _logger = Logger('NativeSync');

/// The sync engine of the native build, wired to the local database.
///
/// Local writes reach the scheduler through [SoarScoreDatabase.localChanges];
/// the remote API becoming reachable restarts every scope that was waiting.
/// Scopes of contests and data owned by the installation's Local account are
/// not synced: they have no account to sync to until sign-in claims them.
///
/// Contests the account owns on the service but this installation has never
/// held are found by listing the account's contests (see
/// [discoverAccountContests]); each is synced from the start of its stream.
class NativeSync {
  NativeSync._(
    this.engine,
    this._scheduler,
    this._subscription,
    this._database,
    this._remote,
    this._discovered,
  ) : appSync = EngineAppSync(engine);

  final ApiClient _remote;

  /// Contests the service lists for the account that are not held locally
  /// yet; shared with the engine's `isSyncable` check.
  final Set<core.Id> _discovered;
  core.Id? _accountId;
  Future<void>? _discovering;

  final SoarScoreDatabase _database;

  /// The engine.
  final SyncEngine engine;

  /// What the screens use; they never see the engine.
  final EngineAppSync appSync;
  final SyncScheduler _scheduler;
  final StreamSubscription<core.SyncScopeKey> _subscription;

  /// Builds the engine over [database], talking to [remote].
  static Future<NativeSync> start({
    required SoarScoreDatabase database,
    required core.Id localAccountId,
    required ApiClient remote,
    required String databasePath,
  }) async {
    final installationId = await InstallationIdFile.besides(databasePath)
        .readOrCreate();
    final contests = ContestRepository(database);
    final discovered = <core.Id>{};
    final engine = SyncEngine(
      store: DriftSyncStore(database),
      applier: DriftReplicatedChangeApplier(
        database,
        EntityStores.forDatabase(database),
      ),
      gateway: ApiClientSyncGateway(remote),
      config: SyncEngineConfig(
        installationId: installationId,
        label: io.Platform.localHostname,
        platform: io.Platform.isWindows
            ? core.Platform.windows
            : core.Platform.other,
        schemaVersion: database.schemaVersion,
        isSyncable: (scope) async => switch (scope) {
          core.ContestScopeKey(:final contestId) => switch (await contests
              .findById(contestId)) {
            // The service lists it for the account: not held here yet.
            null => discovered.contains(contestId),
            final contest => _hasAccount(
              contest.ownerAccountId,
              localAccountId,
            ),
          },
          core.DirectorScopeKey(:final ownerAccountId) => _hasAccount(
            ownerAccountId,
            localAccountId,
          ),
          core.SystemScopeKey() => true,
        },
      ),
    );
    final scheduler = SyncScheduler(engine);
    final subscription = database.localChanges.listen(
      scheduler.notifyLocalChange,
    );
    _logger.info('Sync engine ready for installation $installationId');
    return NativeSync._(
      engine,
      scheduler,
      subscription,
      database,
      remote,
      discovered,
    );
  }

  static bool _hasAccount(core.Id? owner, core.Id localAccountId) =>
      owner != null && owner != localAccountId;

  /// The remote API became reachable (or stopped being so).
  void remoteReachabilityChanged({required bool reachable}) {
    if (!reachable) return;
    _scheduler.connectivityRestored();
    unawaited(discoverAccountContests());
  }

  /// The Local account's data now belongs to [accountId]: sync every scope it
  /// made syncable (the director's own data, the system data and the account's
  /// contests), which were skipped while they were local only.
  Future<void> accountClaimed(core.Id accountId) async {
    _accountId = accountId;
    final scopes = <core.SyncScopeKey>[
      core.DirectorScopeKey(accountId),
      const core.SystemScopeKey(),
    ];
    try {
      for (final contest in await ContestRepository(_database).getAll()) {
        if (contest.ownerAccountId == accountId) {
          scopes.add(core.ContestScopeKey(contest.id));
        }
      }
    } on Object catch (error, stack) {
      // The scheduler knows these scopes from now on, so the contests follow
      // with the next local change or when the service is reachable again.
      _logger.warning('Could not list the claimed contests', error, stack);
    } finally {
      scopes.forEach(_scheduler.notifyLocalChange);
    }
    await discoverAccountContests();
  }

  /// Lists the signed-in account's contests on the service and starts syncing
  /// the ones this installation does not hold, such as a contest made offline
  /// on the director's other installation.
  ///
  /// Does nothing before the account is known (no sign-in claimed yet). A
  /// failure is logged; the next claim or the service becoming reachable
  /// again tries once more. Calls overlapping a running one share it.
  Future<void> discoverAccountContests() {
    if (_accountId == null) return Future.value();
    return _discovering ??= _discover(_accountId!)
        .whenComplete(() => _discovering = null);
  }

  Future<void> _discover(core.Id accountId) async {
    try {
      final held = {
        for (final contest in await ContestRepository(_database).getAll())
          contest.id,
      };
      for (final contest in await _remote.contests()) {
        if (contest.ownerAccountId != accountId || held.contains(contest.id)) {
          continue;
        }
        _discovered.add(contest.id);
        _scheduler.notifyLocalChange(core.ContestScopeKey(contest.id));
      }
    } on Object catch (error, stack) {
      _logger.fine('Could not list the account contests', error, stack);
    }
  }

  Future<void> close() async {
    await _subscription.cancel();
    _scheduler.dispose();
    await appSync.close();
  }
}
