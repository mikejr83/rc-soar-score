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
class NativeSync {
  NativeSync._(this.engine, this._scheduler, this._subscription, this._database)
    : appSync = EngineAppSync(engine);

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
          core.ContestScopeKey(:final contestId) => _hasAccount(
            (await contests.findById(contestId))?.ownerAccountId,
            localAccountId,
          ),
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
    return NativeSync._(engine, scheduler, subscription, database);
  }

  static bool _hasAccount(core.Id? owner, core.Id localAccountId) =>
      owner != null && owner != localAccountId;

  /// The remote API became reachable (or stopped being so).
  void remoteReachabilityChanged({required bool reachable}) {
    if (reachable) _scheduler.connectivityRestored();
  }

  /// The Local account's data now belongs to [accountId]: sync every scope it
  /// made syncable (the director's own data, the system data and the account's
  /// contests), which were skipped while they were local only.
  Future<void> accountClaimed(core.Id accountId) async {
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
  }

  Future<void> close() async {
    await _subscription.cancel();
    _scheduler.dispose();
    await appSync.close();
  }
}
