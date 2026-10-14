import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../router.dart';
import '../../services/sync/sync_status_text.dart';
import 'sync_summary_builder.dart';

/// The sync entry of the shell status panel: what the contest's sync is doing
/// in a few words, and a button to the details. Shows nothing in a build that
/// does not synchronize.
class ShellSyncStatus extends StatelessWidget {
  const ShellSyncStatus({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SyncSummaryBuilder(
      scope: ContestScopeKey(contest.id),
      builder: (context, sync, summary, syncing) {
        if (!sync.available) return const SizedBox.shrink();
        final text = SyncStatusText.of(
          summary,
          syncing: syncing,
          zoneId: contest.timezone,
        );
        final attention =
            (summary?.needsAttention ?? 0) > 0 ||
            (summary != null && summary.localOnly && summary.problem != null);
        return Semantics(
          button: true,
          label: 'Sync: $text',
          excludeSemantics: true,
          child: InkWell(
            key: const ValueKey('shell-sync-status'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.go(contestSyncPath(contest.id.value)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    attention ? Icons.sync_problem : Icons.sync,
                    size: 18,
                    color: attention
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text('Sync', style: theme.textTheme.labelMedium),
                  const SizedBox(width: 8),
                  Text(text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
