import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/activity/activity_entry.dart';
import '../../../services/workspace/activity/activity_facts.dart';
import 'activity_entry_tile.dart';

/// The workspace's "what happened lately" card: the newest events, newest
/// first, with who and when. Presentation only; `RecentActivitySection`
/// reads the facts.
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.contest,
    required this.activity,
    this.onRetry,
    this.onViewAll,
  });

  final Contest contest;

  /// `null` while the facts load.
  final ActivityFacts? activity;

  /// Offered when the read failed.
  final VoidCallback? onRetry;

  /// Opens the full activity page; the View all button is off without it.
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = activity?.entries ?? const <ActivityEntry>[];
    return Card(
      key: const ValueKey('activity-card'),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.activityHeading,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  // Shown whatever the preview holds: it reads only the newest
                  // events, so the full list can hold lines it does not.
                  if (onViewAll != null)
                    TextButton(
                      key: const ValueKey('activity-view-all'),
                      onPressed: onViewAll,
                      child: Text(l10n.activityViewAll),
                    ),
                ],
              ),
            ),
            if (activity == null)
              _note(context, 'activity-loading', l10n.activityLoading)
            else if (activity!.failed)
              _note(
                context,
                'activity-failed',
                l10n.activityFailed,
                retry: onRetry,
              )
            else if (entries.isEmpty)
              _note(context, 'activity-empty', l10n.activityEmpty)
            else
              for (final entry in entries)
                ActivityEntryTile(contest: contest, entry: entry),
          ],
        ),
      ),
    );
  }

  Widget _note(
    BuildContext context,
    String key,
    String text, {
    VoidCallback? retry,
  }) {
    final theme = Theme.of(context);
    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (retry != null)
            TextButton(
              key: const ValueKey('activity-retry'),
              onPressed: retry,
              child: Text(AppLocalizations.of(context).activityRetry),
            ),
        ],
      ),
    );
  }
}
