import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/scoring/pilot_history.dart';
import '../../services/scoring/score_components_text.dart';
import '../../services/workspace/next_step/next_step_text.dart';
import '../api_error_text.dart';
import 'status_chips.dart';

/// Every revision of one row's score, or of a whole group's, newest first.
///
/// [load] gives one [PilotHistory] per pilot; a row's history is a list of
/// one. Times are shown in the contest's zone [zoneId], never the viewer's.
class ScoreHistoryDialog extends StatelessWidget {
  const ScoreHistoryDialog({
    super.key,
    required this.title,
    required this.load,
    required this.landings,
    required this.zoneId,
    this.byPilot = false,
  });

  final String title;
  final Future<List<PilotHistory>> Function() load;
  final List<LandingResult> landings;
  final String zoneId;

  /// Names the pilot over each list: the group view.
  final bool byPilot;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('score-history-dialog'),
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<PilotHistory>>(
          future: load(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                apiErrorText(snapshot.error!),
                key: const ValueKey('score-history-error'),
              );
            }
            final pilots = snapshot.data;
            if (pilots == null) {
              return const Center(
                heightFactor: 2,
                child: CircularProgressIndicator(),
              );
            }
            if (pilots.isEmpty) {
              return Text(
                AppLocalizations.of(context).scoreHistoryEmpty,
                key: const ValueKey('score-history-empty'),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final pilot in pilots) ...[
                  if (byPilot)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        pilot.pilot,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  for (final entry in pilot.entries.reversed)
                    _EntryTile(
                      entry: entry,
                      landings: landings,
                      zoneId: zoneId,
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    AppLocalizations.of(context).scoreHistoryTimesZone(zoneId),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        FilledButton(
          key: const ValueKey('score-history-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).commonClose),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.landings,
    required this.zoneId,
  });

  final ScoreHistoryEntry entry;
  final List<LandingResult> landings;
  final String zoneId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final words = AppLocalizations.of(context);
    String who() => switch (entry.authority) {
      Authority.director => words.scoreHistoryAuthorityDirector,
      Authority.participant => words.scoreHistoryAuthorityParticipant,
      Authority.helper => words.scoreHistoryAuthorityHelper,
      Authority.system => words.scoreHistoryAuthoritySystem,
      Authority.administrator => words.scoreHistoryAuthorityAdmin,
    };
    final (icon, word) = switch (entry.outcome) {
      ScoreHistoryOutcome.current => (
        Icons.verified,
        words.scoreHistoryCurrent,
      ),
      ScoreHistoryOutcome.superseded => (
        Icons.history,
        words.scoreHistoryReplaced,
      ),
      ScoreHistoryOutcome.notAdopted => (
        Icons.block,
        words.scoreHistoryNotAdopted,
      ),
      ScoreHistoryOutcome.pending => (Icons.inbox, words.scoreHistoryPending),
    };
    final revision = entry.scoreRevision;
    // No official actor and an automatic origin: the contest accepted it.
    final automatic =
        entry.selectionOrigin == SelectionOrigin.automatic &&
        entry.outcome != ScoreHistoryOutcome.notAdopted &&
        entry.outcome != ScoreHistoryOutcome.pending;
    // A director adopted a stored participant or helper submission: the
    // entry is that submission, so name who sent it and who made it official.
    final adopted =
        entry.selectionOrigin != null &&
        entry.selectionOrigin != SelectionOrigin.automatic &&
        (entry.authority == Authority.participant ||
            entry.authority == Authority.helper) &&
        entry.outcome != ScoreHistoryOutcome.notAdopted &&
        entry.outcome != ScoreHistoryOutcome.pending;
    final when = entry.at == null ? null : NextStepText.when(entry.at!, zoneId);
    return Card(
      key: ValueKey('history-entry-${entry.attemptId.value}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    revision == null
                        ? words.scoreHistorySubmission
                        : words.scoreHistoryRevision(revision),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                StatusChip(
                  icon: icon,
                  label: word,
                  background: entry.outcome == ScoreHistoryOutcome.current
                      ? scheme.primaryContainer
                      : null,
                  foreground: entry.outcome == ScoreHistoryOutcome.current
                      ? scheme.onPrimaryContainer
                      : null,
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ScoreComponentsText.describe(
                entry.components,
                landings: landings,
              ),
            ),
            if (entry.reason != null)
              Text(words.scoreHistoryReason(entry.reason!)),
            if (automatic)
              Text(
                words.scoreHistoryMadeOfficialBy(words.scoreHistoryAutomatic),
                key: ValueKey('history-automatic-${entry.attemptId.value}'),
              ),
            if (adopted)
              Text(
                '${words.scoreHistoryMadeOfficialBy(words.scoreHistoryDirector)}'
                '${when == null ? '' : ' · $when'}',
                key: ValueKey('history-adopted-${entry.attemptId.value}'),
              ),
            if (automatic && entry.reviewClosed)
              Text(
                words.scoreHistoryConfirmed,
                key: ValueKey('history-confirmed-${entry.attemptId.value}'),
              ),
            Text(
              adopted
                  ? words.scoreHistorySubmittedBy(who())
                  : (when == null ? who() : '${who()} · $when'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
