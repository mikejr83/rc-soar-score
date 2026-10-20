import '../preferences/director_time.dart';

import 'sync_scope_summary.dart';

/// The one-line sync status for the shell, in the director's preferred time zone and locale.
abstract final class SyncStatusText {
  /// What [summary] says in a few words. [summary] is null before the engine
  /// has looked at the scope.
  static String of(
    SyncScopeSummary? summary, {
    required bool syncing,
    required TimeText time,
  }) {
    if (summary == null) return 'Checking…';
    if (summary.localOnly) {
      final problem = summary.problem;
      return problem == null ? 'Local only' : 'Local only · ${problem.label}';
    }
    if (syncing) return 'Syncing…';
    final parts = <String>[
      if (summary.problem != null)
        summary.problem!.label
      else if (summary.lastSyncedAt != null)
        'Synced ${time(summary.lastSyncedAt!)}'
      else
        'Not synced yet',
      if (summary.needsAttention > 0)
        '${summary.needsAttention} '
            '${summary.needsAttention == 1 ? 'needs' : 'need'} attention',
      if (summary.pendingChanges > 0) '${summary.pendingChanges} pending',
    ];
    return parts.join(' · ');
  }
}
