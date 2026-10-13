import 'sync_failure_kind.dart';
import 'sync_skip_reason.dart';

/// What the director sees about one scope.
class SyncScopeState {
  const SyncScopeState({
    required this.pendingMutations,
    required this.conflictsNeedingAction,
    required this.lastSyncedSequence,
    this.lastSyncedAt,
    this.remoteSequence,
    this.failure,
    this.skipReason,
  });

  /// Mutations still in the outbox.
  final int pendingMutations;

  /// Conflicts the director has to decide.
  final int conflictsNeedingAction;

  final int lastSyncedSequence;

  /// When the scope last synced successfully; null before the first sync.
  final DateTime? lastSyncedAt;

  /// The scope's highest sequence on the service as of the last exchange.
  final int? remoteSequence;

  /// Why the last attempt failed; null when it succeeded or none was made.
  final SyncFailureKind? failure;

  /// Set when the scope is not synchronized at all.
  final SyncSkipReason? skipReason;
}
