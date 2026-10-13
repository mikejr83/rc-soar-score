import 'package:soar_score_core/soar_score_core.dart';

/// An in-memory [SyncStore] that keeps the real store's rules: the cursor
/// never moves back and only `Pending` rows are in the outbox.
class FakeSyncStore implements SyncStore {
  FakeSyncStore(this.log);

  /// Shared with the other fakes so a test can assert the order of events.
  final List<String> log;

  final mutations = <MutationRecord>[];
  final cursors = <SyncScopeKey, int>{};
  final syncedAt = <SyncScopeKey, DateTime>{};
  var conflicts = 0;

  @override
  Future<List<MutationRecord>> pendingMutations(SyncScopeKey scope) async => [
    for (final m in mutations)
      if (m.outcome == MutationOutcome.pending) m,
  ];

  @override
  Future<void> recordOutcome({
    required Id mutationId,
    required MutationOutcome outcome,
    int? sequence,
    DateTime? serverAcceptanceTime,
    DateTime? serverRejectionTime,
    String? reasonCode,
    String? errorMessage,
  }) async {
    log.add('outcome:${outcome.name}');
    final index = mutations.indexWhere((m) => m.id == mutationId);
    mutations[index] = MutationRecord.fromJson({
      ...mutations[index].toJson(),
      'outcome': switch (outcome) {
        MutationOutcome.pending => 'Pending',
        MutationOutcome.accepted => 'Accepted',
        MutationOutcome.rejected => 'Rejected',
        MutationOutcome.conflict => 'Conflict',
        MutationOutcome.skipped => 'Skipped',
      },
      'sequence': sequence,
      'reason_code': reasonCode,
    });
  }

  @override
  Future<int> readCursor(SyncScopeKey scope) async => cursors[scope] ?? 0;

  @override
  Future<void> writeCursor(
    SyncScopeKey scope,
    int lastSyncedSequence, {
    DateTime? syncedAt,
  }) async {
    if (lastSyncedSequence < (cursors[scope] ?? 0)) {
      throw ArgumentError.value(lastSyncedSequence, 'lastSyncedSequence');
    }
    log.add('cursor:$lastSyncedSequence');
    cursors[scope] = lastSyncedSequence;
    if (syncedAt != null) this.syncedAt[scope] = syncedAt;
  }

  @override
  Future<List<ConflictRecord>> conflictsNeedingAction(
    SyncScopeKey scope,
  ) async => const [];

  @override
  Future<SyncStatus> status(SyncScopeKey scope) async => SyncStatus(
    pendingMutations: (await pendingMutations(scope)).length,
    conflictsNeedingAction: conflicts,
    lastSyncedSequence: cursors[scope] ?? 0,
    lastSyncedAt: syncedAt[scope],
  );
}
