import 'package:material_ui/material_ui.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/preferences/director_time.dart';
import '../../services/sync/sync_problem.dart';
import '../../services/sync/sync_scope_summary.dart';

/// The numbers and messages behind the sync status of one contest, and the
/// Sync now button.
class SyncDetailsCard extends StatelessWidget {
  const SyncDetailsCard({
    super.key,
    required this.summary,
    required this.syncing,
    required this.onSyncNow,
  });

  final SyncScopeSummary? summary;
  final bool syncing;

  /// The contest's time zone, for the last sync time.

  /// Null when a sync cannot be started now.
  final VoidCallback? onSyncNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final dark = theme.brightness == Brightness.dark;
    final summary = this.summary;
    final problem = summary?.problem;
    return Card(
      key: const ValueKey('sync-details-card'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.syncTitle, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            if (summary == null)
              Text(l10n.syncChecking)
            else if (summary.localOnly) ...[
              Text(l10n.syncLocalOnlyText, key: const ValueKey('sync-local-only')),
              if (problem != null) ..._problemRow(theme, dark, problem),
            ] else ...[
              _row(
                theme,
                l10n.syncLastSynced,
                summary.lastSyncedAt == null
                    ? l10n.syncNotSyncedYet
                    : DirectorTime.of(context)(summary.lastSyncedAt!),
              ),
              _row(
                theme,
                l10n.syncWaitingToSend,
                '${summary.pendingChanges}',
              ),
              _row(
                theme,
                l10n.syncRefusedByService,
                '${summary.rejectedChanges}',
              ),
              _row(theme, l10n.syncConflictsToDecide, '${summary.conflicts}'),
              if (summary.waitingForNewerService > 0)
                _row(
                  theme,
                  l10n.syncWaitingForNewerService,
                  '${summary.waitingForNewerService}',
                ),
              if (problem != null) ..._problemRow(theme, dark, problem),
            ],
            const SizedBox(height: 12),
            Text(
              l10n.syncUnrecoverableWarning,
              key: const ValueKey('sync-unrecoverable-warning'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('sync-now'),
              onPressed: onSyncNow,
              icon: syncing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(syncing ? l10n.syncSyncing : l10n.syncNow),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _problemRow(ThemeData theme, bool dark, SyncProblem problem) => [
    const SizedBox(height: 12),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 20,
          color: AppStatusColors.getWarning(dark),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                problem.label,
                key: const ValueKey('sync-problem'),
                style: theme.textTheme.titleSmall,
              ),
              Text(problem.explanation),
            ],
          ),
        ),
      ],
    ),
  ];

  Widget _row(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    ),
  );
}
