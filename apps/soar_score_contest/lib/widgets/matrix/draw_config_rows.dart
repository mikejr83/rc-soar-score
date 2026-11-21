import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/matrix/matrix_page_data.dart';

import 'package:soar_score_core/soar_score_core.dart';

/// The draw settings that come from the contest configuration, read-only
/// here, each with a link to change it in Configuration.
class DrawConfigRows extends StatelessWidget {
  const DrawConfigRows({
    super.key,
    required this.data,
    required this.onOpenConfiguration,
  });

  final MatrixPageData data;
  final VoidCallback onOpenConfiguration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final options = data.options;
    final seeded = options?.drawMode == DrawMode.seededManOnMan;
    final protection = options?.teamProtection ?? false;
    final backToBack = options?.allowBackToBack ?? true;
    final pilots = data.scoringPilots;
    final excluded = data.nonFlyingParticipants;
    final laneMode = options?.laneMode ?? LaneMode.none;
    final rows = <(IconData, String, String, String, bool)>[
      if (options?.teamsEnabled ?? false)
        (
          Icons.shield_outlined,
          l10n.wizardTeamProtection,
          protection ? l10n.matrixValueOn : l10n.matrixValueOff,
          protection
              ? l10n.matrixTeamProtectionNote
              : seeded
              ? l10n.matrixTeamProtectionSeededOffNote
              : '',
          true,
        ),
      (
        Icons.shuffle,
        l10n.wizardDrawMode,
        seeded ? l10n.wizardDrawModeSeeded : l10n.wizardDrawModeManOnMan,
        seeded
            ? l10n.matrixSeededPrelimNote(options?.preliminaryRounds ?? 1)
            : '',
        true,
      ),
      (
        Icons.swap_vert,
        l10n.matrixBackToBackLabel,
        backToBack ? l10n.wizardAllowed : l10n.wizardAvoided,
        backToBack ? '' : l10n.matrixBackToBackOffNote,
        true,
      ),
      (
        Icons.view_column_outlined,
        l10n.matrixLaneModeLabel,
        laneMode == LaneMode.random
            ? l10n.matrixLaneRandom
            : l10n.matrixLaneNone,
        laneMode == LaneMode.random
            ? l10n.matrixLaneRandomNote
            : l10n.matrixLaneNoneNote,
        true,
      ),
      (
        Icons.groups_outlined,
        l10n.matrixPilotsInDrawLabel,
        l10n.matrixPilotsInDrawValue(pilots, pilots == 1 ? '' : 's'),
        excluded > 0
            ? l10n.matrixNonFlyingExcluded(
                excluded,
                excluded == 1 ? ' is' : 's are',
              )
            : '',
        true,
      ),
      (
        Icons.history,
        l10n.matrixConfigRevisionLabel,
        '${data.configuration?.revisionNumber ?? '–'}',
        '',
        false,
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Wrap(
              spacing: 12,
              children: [
                Text(
                  l10n.matrixConfigFromTitle,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  l10n.matrixConfigReadOnlyNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final (icon, label, value, note, link) in rows) ...[
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (note.isNotEmpty)
                          Text(
                            note,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (link)
                    Semantics(
                      label: l10n.matrixChangeInConfig(label.toLowerCase()),
                      excludeSemantics: true,
                      button: true,
                      child: TextButton.icon(
                        onPressed: onOpenConfiguration,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: Text(l10n.matrixChange),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
