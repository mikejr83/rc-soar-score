import '../../l10n/app_localizations.dart';
import '../preferences/director_time.dart';
import 'sync_scope_summary.dart';

/// What the shell's sync entry says: a few words for the bar and the longer
/// description for its tooltip.
class SyncStatusText {
  const SyncStatusText({required this.label, required this.tooltip});

  /// A few words for the status bar.
  final String label;

  /// The details that would crowd the bar: when the scope last synced, what
  /// is waiting, why it failed.
  final String tooltip;

  /// The status of [summary], which is null before the engine has looked at
  /// the scope. Times come out in the director's preferred zone and locale.
  /// [canSyncNow] adds the hint that a click syncs.
  static SyncStatusText of(
    AppLocalizations l10n,
    SyncScopeSummary? summary, {
    required bool syncing,
    required TimeText time,
    bool canSyncNow = false,
  }) {
    if (summary == null) {
      final label = l10n.syncStatusChecking;
      return SyncStatusText(label: label, tooltip: label);
    }
    final problem = summary.problem;
    final String label;
    if (summary.localOnly) {
      label = l10n.syncStatusLocalOnly;
    } else if (syncing) {
      label = l10n.syncStatusSyncing;
    } else if (problem != null) {
      label = l10n.syncStatusFailed;
    } else if (summary.conflicts > 0) {
      label = l10n.syncStatusConflicts;
    } else if (summary.rejectedChanges > 0) {
      label = l10n.syncStatusRefused;
    } else if (summary.lastSyncedAt == null) {
      label = l10n.syncStatusNotSynced;
    } else if (summary.pendingChanges > 0) {
      label = l10n.syncStatusPending;
    } else {
      label = l10n.syncStatusSuccessful;
    }

    final lines = <String>[
      label,
      if (problem != null) '${problem.label}. ${problem.explanation}',
      if (summary.localOnly)
        l10n.syncTooltipLocalOnly
      else if (summary.lastSyncedAt != null)
        l10n.syncTooltipLastSynced(time(summary.lastSyncedAt!))
      else if (summary.lastSyncedAt == null &&
          label != l10n.syncStatusNotSynced)
        l10n.syncStatusNotSynced,
      if (summary.pendingChanges > 0)
        l10n.syncTooltipPending(summary.pendingChanges),
      if (summary.needsAttention > 0)
        l10n.syncTooltipAttention(summary.needsAttention),
      if (canSyncNow && !syncing && !summary.localOnly) l10n.syncTooltipAction,
    ];
    return SyncStatusText(label: label, tooltip: lines.join('\n'));
  }
}
