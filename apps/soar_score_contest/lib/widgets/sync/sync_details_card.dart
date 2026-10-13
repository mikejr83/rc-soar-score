import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../services/sync/sync_scope_summary.dart';

/// The numbers and messages behind the sync status of one contest, and the
/// Sync now button.
class SyncDetailsCard extends StatelessWidget {
  const SyncDetailsCard({
    super.key,
    required this.summary,
    required this.syncing,
    required this.zoneId,
    required this.onSyncNow,
  });

  final SyncScopeSummary? summary;
  final bool syncing;

  /// The contest's time zone, for the last sync time.
  final String zoneId;

  /// Null when a sync cannot be started now.
  final VoidCallback? onSyncNow;

  /// The reminder that is always shown.
  static const String unrecoverableWarning =
      'Changes made after the last successful sync cannot be recovered if '
      'this installation is lost.';

  static const String localOnlyText =
      'This contest is local only. It has no remote backup and does not '
      'sync until it is tied to an account.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              child: Text('Sync', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            if (summary == null)
              const Text('Checking…')
            else if (summary.localOnly)
              const Text(localOnlyText, key: ValueKey('sync-local-only'))
            else ...[
              _row(
                theme,
                'Last synced',
                summary.lastSyncedAt == null
                    ? 'Not synced yet'
                    : ContestTime.format(summary.lastSyncedAt!, zoneId),
              ),
              _row(theme, 'Waiting to be sent', '${summary.pendingChanges}'),
              _row(
                theme,
                'Refused by the service',
                '${summary.rejectedChanges}',
              ),
              _row(theme, 'Conflicts to decide', '${summary.conflicts}'),
              if (problem != null) ...[
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
              ],
            ],
            const SizedBox(height: 12),
            Text(
              unrecoverableWarning,
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
              label: Text(syncing ? 'Syncing…' : 'Sync now'),
            ),
          ],
        ),
      ),
    );
  }

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
