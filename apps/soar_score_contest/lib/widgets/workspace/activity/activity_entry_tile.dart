import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/activity/activity_entry.dart';

/// The row width from which a line's time sits beside its text.
const double _sideBySideWidth = 420;

/// One line of an activity list: an icon, what happened and when (in the
/// contest's time zone). Shared by the workspace's Recent activity card and
/// the full activity page.
class ActivityEntryTile extends StatelessWidget {
  const ActivityEntryTile({
    super.key,
    required this.contest,
    required this.entry,
  });

  final Contest contest;
  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
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
    ActivityKind.scoreCorrected => Icons.edit_note_outlined,
    ActivityKind.pilotRetired => Icons.logout,
    ActivityKind.pilotReinstated => Icons.login,
  };

  static String _text(BuildContext context, ActivityEntry entry) {
    final l10n = AppLocalizations.of(context);
    // The ARB messages use ICU `select`: "you" or anything else ("other").
    final actor = entry.byYou ? 'you' : 'other';
    // The pilot is "none" when the event does not name one. Every event that
    // reaches a line with a round names it, so 0 is only a placeholder.
    final pilot = entry.pilot?.toString() ?? 'none';
    final round = entry.round ?? 0;
    return switch (entry.kind) {
      ActivityKind.complete => l10n.activityComplete(actor),
      ActivityKind.openScoring => l10n.activityOpenScoring(actor),
      ActivityKind.closeScoring => l10n.activityCloseScoring(actor),
      ActivityKind.lock => l10n.activityLock(actor),
      ActivityKind.unlock => l10n.activityUnlock(actor),
      ActivityKind.publication => l10n.activityPublication(actor),
      ActivityKind.configurationSaved => l10n.activityConfigurationSaved(actor),
      ActivityKind.matrixDrawn => l10n.activityMatrixDrawn(actor),
      ActivityKind.scoreCorrected => l10n.activityScoreCorrected(
        actor,
        pilot,
        round,
      ),
      ActivityKind.pilotRetired => l10n.activityPilotRetired(
        actor,
        pilot,
        round,
      ),
      ActivityKind.pilotReinstated => l10n.activityPilotReinstated(
        actor,
        pilot,
      ),
    };
  }
}
