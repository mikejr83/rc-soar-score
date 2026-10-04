import 'package:equatable/equatable.dart';

/// What the director sees about one scope's synchronization.
class SyncStatus extends Equatable {
  const SyncStatus({
    required this.pendingMutations,
    required this.conflictsNeedingAction,
    required this.lastSyncedSequence,
    this.lastSyncedAt,
  });

  /// Mutations still in the outbox.
  final int pendingMutations;

  /// Conflicts the director has to decide.
  final int conflictsNeedingAction;

  final int lastSyncedSequence;
  final DateTime? lastSyncedAt;

  @override
  List<Object?> get props => [
    pendingMutations,
    conflictsNeedingAction,
    lastSyncedSequence,
    lastSyncedAt,
  ];
}
