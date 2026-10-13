import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_sync/soar_score_sync.dart';

import '../services/sync/app_sync.dart';
import '../services/sync/app_sync_state.dart';
import '../services/sync/refused_change.dart';
import '../services/sync/sync_problem.dart';
import '../services/sync/sync_scope_summary.dart';

/// [AppSync] over the sync engine of the native build.
class EngineAppSync implements AppSync {
  EngineAppSync(this._engine) {
    _subscription = _engine.states.listen((next) {
      if (!_controller.isClosed) _controller.add(_translate(next));
    });
  }

  final SyncEngine _engine;
  final _controller = StreamController<AppSyncState>.broadcast();
  late final StreamSubscription<SyncState> _subscription;

  @override
  bool get available => true;

  @override
  AppSyncState get state => _translate(_engine.state);

  @override
  Stream<AppSyncState> get states => _controller.stream;

  @override
  Future<void> refresh(core.SyncScopeKey scope) => _engine.refresh(scope);

  @override
  Future<void> syncNow(core.SyncScopeKey scope) async {
    await _engine.syncScope(scope);
  }

  @override
  Future<List<RefusedChange>> refusedChanges(core.SyncScopeKey scope) async => [
    for (final mutation in await _engine.rejectedMutations(scope))
      RefusedChange(
        entityType: mutation.entityType,
        entityId: mutation.entityId,
        madeAt: mutation.clientTime,
        reasonCode: mutation.reasonCode,
        message: mutation.errorMessage,
      ),
  ];

  Future<void> close() async {
    await _subscription.cancel();
    await _controller.close();
  }

  static AppSyncState _translate(SyncState state) => AppSyncState(
    syncing: state.syncing,
    scopes: {
      for (final entry in state.scopes.entries)
        entry.key: SyncScopeSummary(
          pendingChanges: entry.value.pendingMutations,
          rejectedChanges: entry.value.rejectedMutations,
          conflicts: entry.value.conflictsNeedingAction,
          lastSyncedAt: entry.value.lastSyncedAt,
          problem: _problem(entry.value.failure),
          localOnly: entry.value.skipReason == SyncSkipReason.accountless,
        ),
    },
  );

  static SyncProblem? _problem(SyncFailureKind? kind) => switch (kind) {
    null => null,
    SyncFailureKind.offline => SyncProblem.offline,
    SyncFailureKind.tokenExpired => SyncProblem.signInExpired,
    SyncFailureKind.serverError => SyncProblem.serverError,
    SyncFailureKind.updateRequired => SyncProblem.updateRequired,
    SyncFailureKind.inactiveInstallation => SyncProblem.inactiveInstallation,
    SyncFailureKind.unsupportedChange => SyncProblem.unsupportedChange,
  };
}
