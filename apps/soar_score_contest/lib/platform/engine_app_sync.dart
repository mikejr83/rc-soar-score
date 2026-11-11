import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_sync/soar_score_sync.dart';

import '../services/sync/app_sync.dart';
import '../services/sync/app_sync_state.dart';
import '../services/sync/conflict_answer.dart';
import '../services/sync/open_conflict.dart';
import '../services/sync/reason_text.dart';
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
  SyncProblem? _claimProblem;
  final _controller = StreamController<AppSyncState>.broadcast();
  late final StreamSubscription<SyncState> _subscription;

  @override
  bool get available => true;

  core.SyncScopeKey? _accountScope;

  @override
  core.SyncScopeKey? get accountScope => _accountScope;

  /// The signed-in account's own data scope, or null while nobody is.
  void accountScopeChanged(core.SyncScopeKey? scope) {
    if (scope == _accountScope) return;
    _accountScope = scope;
    if (!_controller.isClosed) _controller.add(state);
  }

  @override
  AppSyncState get state => _translate(_engine.state);

  /// Why the offline data could not be linked to the signed-in account, or
  /// null. It shows on the scopes that are still local only.
  void claimProblemChanged(SyncProblem? problem) {
    if (problem == _claimProblem) return;
    _claimProblem = problem;
    if (!_controller.isClosed) _controller.add(state);
  }

  @override
  Stream<AppSyncState> get states => _controller.stream;

  @override
  Future<void> refresh(core.SyncScopeKey scope) => _engine.refresh(scope);

  @override
  Future<void> syncNow(core.SyncScopeKey scope) async {
    await _engine.syncScope(scope);
  }

  @override
  Future<List<RefusedChange>> refusedChanges(core.SyncScopeKey scope) async {
    final changes = [
      for (final mutation in await _engine.rejectedMutations(scope))
        RefusedChange(
          entityType: mutation.entityType,
          entityId: mutation.entityId,
          madeAt: mutation.clientTime,
          reasonCode: mutation.reasonCode,
          message: mutation.errorMessage,
        ),
    ];
    // Newest first.
    changes.sort((a, b) => b.madeAt.compareTo(a.madeAt));
    return changes;
  }

  @override
  Future<List<OpenConflict>> openConflicts(core.SyncScopeKey scope) async => [
    for (final conflict in await _engine.openConflicts(scope))
      OpenConflict(
        id: conflict.id,
        entityType: conflict.entityType,
        entityId: conflict.entityId,
        createdAt: conflict.createdAt,
        reasonCode: conflict.reasonCode,
        reason: conflict.reason,
        acceptedPayload: conflict.acceptedPayload,
        competingPayload: conflict.competingPayload,
      ),
  ];

  @override
  Future<ConflictAnswer> resolveConflict(
    core.SyncScopeKey scope,
    OpenConflict conflict,
    core.ConflictResolutionChoice choice, {
    Map<String, Object?>? payload,
  }) async {
    final outcome = await _engine.resolveConflict(
      scope,
      conflict.id,
      clientMutationId: core.Id.create().toString(),
      choice: choice,
      payload: payload,
    );
    final failure = _problem(outcome.failure);
    if (outcome.result == null && failure != null) {
      return ConflictAnswer.failed(failure);
    }
    if (outcome.accepted) {
      return ConflictAnswer.resolved(refreshProblem: failure);
    }
    return ConflictAnswer.notAccepted(_refusal(outcome));
  }

  static String _refusal(ResolveConflictOutcome outcome) {
    const base = 'The service did not accept the decision.';
    final code = outcome.result?.reasonCode;
    return code == null || code.isEmpty ? base : '$base ${reasonText(code)}';
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _controller.close();
  }

  AppSyncState _translate(SyncState state) => AppSyncState(
    syncing: state.syncing,
    scopes: {
      for (final entry in state.scopes.entries)
        entry.key: SyncScopeSummary(
          pendingChanges: entry.value.pendingMutations,
          rejectedChanges: entry.value.rejectedMutations,
          conflicts: entry.value.conflictsNeedingAction,
          lastSyncedAt: entry.value.lastSyncedAt,
          dataRevision: entry.value.dataRevision,
          problem:
              _problem(entry.value.failure) ??
              (entry.value.skipReason == SyncSkipReason.accountless
                  ? _claimProblem
                  : null),
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
