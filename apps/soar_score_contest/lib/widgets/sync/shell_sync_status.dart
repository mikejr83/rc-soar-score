import 'dart:async';

import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../app_sync_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/preferences/director_time.dart';
import '../../services/sync/sync_status_text.dart';
import 'sync_summary_builder.dart';

/// The sync entry of the status bar: what the sync is doing in a few words
/// ("Sync successful", "Sync failed", "Sync conflicts"). Hovering it shows
/// the details, such as when it last synced, and a tap syncs now.
///
/// In a contest it is that contest's sync; the details page is in the
/// contest's navigation. Outside a contest it is the signed-in account's own
/// data.
/// The web build has no sync; there it is a Refresh entry that reloads the
/// data on screen (`RevisionAppSync`).
///
/// Shows nothing in a build that neither synchronizes nor refreshes, or outside
/// a contest while nobody is signed in.
class ShellSyncStatus extends StatelessWidget {
  const ShellSyncStatus({super.key, this.contest});

  /// The selected contest, or null outside one.
  final Contest? contest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contest = this.contest;
    final scope = contest == null
        ? appSyncOf(context).accountScope
        : ContestScopeKey(contest.id);
    if (scope == null) return const SizedBox.shrink();
    return SyncSummaryBuilder(
      scope: scope,
      builder: (context, sync, summary, syncing) {
        if (!sync.available && !sync.refreshable) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context);
        final time = DirectorTime.of(context);
        final text = sync.available
            ? SyncStatusText.of(
                l10n,
                summary,
                syncing: syncing,
                time: time,
                canSyncNow: true,
              )
            : SyncStatusText.ofRefresh(
                l10n,
                summary,
                syncing: syncing,
                time: time,
              );
        final attention =
            (summary?.needsAttention ?? 0) > 0 ||
            (summary != null && summary.localOnly && summary.problem != null) ||
            (summary?.problem != null && !syncing);
        return Tooltip(
          message: text.tooltip,
          child: Semantics(
            button: true,
            label: sync.available
                ? l10n.syncSemanticsLabel(text.label)
                : l10n.refreshSemanticsLabel(text.label),
            excludeSemantics: true,
            child: InkWell(
              key: const ValueKey('shell-sync-status'),
              borderRadius: BorderRadius.circular(8),
              onTap: syncing ? null : () => unawaited(sync.syncNow(scope)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    attention ? Icons.sync_problem : Icons.sync,
                    size: 16,
                    color: attention
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(text.label, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
