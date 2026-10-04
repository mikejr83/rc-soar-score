import '../enums/mutation_outcome.dart';
import '../models/id.dart';
import '../models/sync/conflict_record.dart';
import '../models/sync/mutation_record.dart';
import 'sync_scope_key.dart';
import 'sync_status.dart';

/// The client's view of synchronization state for one scope at a time.
abstract interface class SyncStore {
  /// Mutations still `Pending` in the outbox, oldest first.
  Future<List<MutationRecord>> pendingMutations(SyncScopeKey scope);

  /// Records the service's answer for a mutation in the outbox.
  ///
  /// [sequence] accompanies an `Accepted` outcome only.
  Future<void> recordOutcome({
    required Id mutationId,
    required MutationOutcome outcome,
    int? sequence,
    DateTime? serverAcceptanceTime,
    DateTime? serverRejectionTime,
    String? reasonCode,
    String? errorMessage,
  });

  /// The highest sequence of [scope] stored locally; 0 before any sync.
  Future<int> readCursor(SyncScopeKey scope);

  /// Advances the cursor. Call it only after the returned changes are durably
  /// stored. The position never decreases; writing a lower one is an error.
  Future<void> writeCursor(
    SyncScopeKey scope,
    int lastSyncedSequence, {
    DateTime? syncedAt,
  });

  /// Conflicts in [scope] that the director has to decide.
  Future<List<ConflictRecord>> conflictsNeedingAction(SyncScopeKey scope);

  Future<SyncStatus> status(SyncScopeKey scope);
}
