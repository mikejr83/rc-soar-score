import 'sync_failure_kind.dart';
import 'sync_skip_reason.dart';

/// What the director sees about one scope.
class SyncScopeState {
  const SyncScopeState({
    required this.pendingMutations,
    required this.conflictsNeedingAction,
    required this.lastSyncedSequence,
    this.rejectedMutations = 0,
    this.lastSyncedAt,
    this.remoteSequence,
    this.dataRevision = 0,
    this.failure,
    this.skipReason,
  });

  /// Mutations still in the outbox.
  final int pendingMutations;

  /// Conflicts the director has to decide.
  final int conflictsNeedingAction;

  /// Mutations the service rejected, kept so the director can see them.
  final int rejectedMutations;

  final int lastSyncedSequence;

  /// When the scope last synced successfully; null before the first sync.
  final DateTime? lastSyncedAt;

  /// The scope's highest sequence on the service as of the last exchange.
  final int? remoteSequence;

  /// Counts the exchanges of this scope that changed local data (a pulled
  /// change applied) or what the service holds (a pushed change accepted).
  /// Screens reload when it moves; a sync that changed nothing leaves it.
  final int dataRevision;

  /// Why the last attempt failed; null when it succeeded or none was made.
  final SyncFailureKind? failure;

  /// Set when the scope is not synchronized at all.
  final SyncSkipReason? skipReason;
}
