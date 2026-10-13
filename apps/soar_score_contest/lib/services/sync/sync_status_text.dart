import 'package:soar_score_core/soar_score_core.dart';

import 'sync_scope_summary.dart';

/// The one-line sync status for the shell, in the contest's time zone.
abstract final class SyncStatusText {
  /// What [summary] says in a few words. [summary] is null before the engine
  /// has looked at the scope.
  static String of(
    SyncScopeSummary? summary, {
    required bool syncing,
    required String zoneId,
  }) {
    if (summary == null) return 'Checking…';
    if (summary.localOnly) return 'Local only';
    if (syncing) return 'Syncing…';
    final parts = <String>[
      if (summary.problem != null)
        summary.problem!.label
      else if (summary.lastSyncedAt != null)
        'Synced ${ContestTime.format(summary.lastSyncedAt!, zoneId)}'
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
