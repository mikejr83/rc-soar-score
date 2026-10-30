import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/activity/activity_entry.dart';
import '../../../services/workspace/activity/activity_facts.dart';

/// The workspace's "what happened lately" card: the newest events, newest
/// first, with who and when. Presentation only; `RecentActivitySection`
/// reads the facts.
/// The row width from which a line's time sits beside its text.
const double _sideBySideWidth = 420;

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.contest,
    required this.activity,
    this.onRetry,
  });

  final Contest contest;

  /// `null` while the facts load.
  final ActivityFacts? activity;

  /// Offered when the read failed.
  final VoidCallback? onRetry;

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
                  if (entries.isNotEmpty)
                    // The audit view is a later page, so the button is off.
                    TextButton(
                      key: const ValueKey('activity-view-all'),
                      onPressed: null,
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
            else ...[
              for (final entry in entries) _row(context, entry),
              _note(
                context,
                'activity-view-all-note',
                l10n.activityViewAllUnavailable,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ActivityEntry entry) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final text = Text(_text(context, entry), style: theme.textTheme.bodyMedium);
    final when = Text(
      _when(entry.at),
      style: theme.textTheme.bodySmall?.copyWith(color: muted),
    );
    return Padding(
      // The event id, not the kind, identifies a row: several events can share
      // a kind (a configuration saved twice).
      key: ValueKey('activity-row-${entry.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Icon(_icon(entry.kind), size: 20, color: muted),
            ),
          ),
          const SizedBox(width: 12),
          // The time sits beside the text when there is room, under it
          // otherwise (a narrow window or large text).
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => box.maxWidth >= _sideBySideWidth
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: 12),
                        when,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [text, when],
                    ),
            ),
          ),
        ],
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

  String _when(DateTime at) => ContestTime.format(
    at,
    ContestTimeZones.isValid(contest.timezone)
        ? contest.timezone
        : ContestTimeZones.utc,
  );

  static IconData _icon(ActivityKind kind) => switch (kind) {
    ActivityKind.complete => Icons.flag_outlined,
    ActivityKind.openScoring => Icons.how_to_reg_outlined,
    ActivityKind.closeScoring => Icons.person_off_outlined,
    ActivityKind.lock => Icons.lock_outline,
    ActivityKind.unlock => Icons.lock_open_outlined,
    ActivityKind.publication => Icons.public,
    ActivityKind.configurationSaved => Icons.tune_outlined,
    ActivityKind.matrixDrawn => Icons.grid_on_outlined,
  };

  static String _text(BuildContext context, ActivityEntry entry) {
    final l10n = AppLocalizations.of(context);
    // The ARB messages use ICU `select`: "you" or anything else ("other").
    final actor = entry.byYou ? 'you' : 'other';
    return switch (entry.kind) {
      ActivityKind.complete => l10n.activityComplete(actor),
      ActivityKind.openScoring => l10n.activityOpenScoring(actor),
      ActivityKind.closeScoring => l10n.activityCloseScoring(actor),
      ActivityKind.lock => l10n.activityLock(actor),
      ActivityKind.unlock => l10n.activityUnlock(actor),
      ActivityKind.publication => l10n.activityPublication(actor),
      ActivityKind.configurationSaved => l10n.activityConfigurationSaved(actor),
      ActivityKind.matrixDrawn => l10n.activityMatrixDrawn(actor),
    };
  }
}
