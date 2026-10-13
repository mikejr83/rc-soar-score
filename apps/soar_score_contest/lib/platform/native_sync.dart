import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

import 'installation_id_file.dart';

final _logger = Logger('NativeSync');

/// The sync engine of the native build, wired to the local database.
///
/// Local writes reach the scheduler through [SoarScoreDatabase.localChanges];
/// the remote API becoming reachable restarts every scope that was waiting.
/// Scopes of contests and data owned by the installation's Local account are
/// not synced: they have no account to sync to until sign-in claims them.
class NativeSync {
  NativeSync._(this.engine, this._scheduler, this._subscription);

  /// The engine, for the sync status and conflict screens.
  final SyncEngine engine;
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
    return NativeSync._(engine, scheduler, subscription);
  }

  static bool _hasAccount(core.Id? owner, core.Id localAccountId) =>
      owner != null && owner != localAccountId;

  /// The remote API became reachable (or stopped being so).
  void remoteReachabilityChanged({required bool reachable}) {
    if (reachable) _scheduler.connectivityRestored();
  }

  Future<void> close() async {
    await _subscription.cancel();
    _scheduler.dispose();
  }
}
