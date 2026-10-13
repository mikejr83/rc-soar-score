import 'package:equatable/equatable.dart';

import 'sync_problem.dart';

/// What the director sees about the sync of one scope (a contest, or the
/// director's own data).
class SyncScopeSummary extends Equatable {
  const SyncScopeSummary({
    this.pendingChanges = 0,
    this.rejectedChanges = 0,
    this.conflicts = 0,
    this.lastSyncedAt,
    this.problem,
    this.localOnly = false,
  });

  /// Changes made here that the service has not yet answered.
  final int pendingChanges;

  /// Changes the service refused.
  final int rejectedChanges;

  /// Conflicts that need the director's decision.
  final int conflicts;

  /// When the scope last synced; null before the first sync.
  final DateTime? lastSyncedAt;

  /// Why the last attempt failed; null when it did not.
  final SyncProblem? problem;

  /// True for data with no account behind it: it is not backed up.
  final bool localOnly;

  /// Rejected changes and conflicts: what the director has to look at.
  int get needsAttention => rejectedChanges + conflicts;

  @override
  List<Object?> get props => [
    pendingChanges,
    rejectedChanges,
    conflicts,
    lastSyncedAt,
    problem,
    localOnly,
  ];
}
