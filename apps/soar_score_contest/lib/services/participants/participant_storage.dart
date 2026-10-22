import '../sync/sync_scope_summary.dart';

/// Where a stored profile currently lives, as the edit page's chip shows it.
enum ParticipantStorage {
  synced('Synced'),
  localOnly('Local only, not yet synced');

  const ParticipantStorage(this.label);

  final String label;

  /// The state for a profile in the director's sync scope, or null when
  /// there is nothing to say (this build does not sync, or the engine has
  /// not looked at the scope yet).
  static ParticipantStorage? of(SyncScopeSummary? summary) {
    if (summary == null) {
      return null;
    }
    if (summary.localOnly || summary.pendingChanges > 0) {
      return localOnly;
    }
    return summary.lastSyncedAt == null ? null : synced;
  }
}
