import 'package:flutter/material.dart';

import '../../services/matrix/matrix_page_data.dart';
import '../../services/matrix/config_drift.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final options = data.options;
    final seeded = options?.drawMode == DrawMode.seededManOnMan;
    final protection = options?.teamProtection ?? false;
    final backToBack = options?.allowBackToBack ?? true;
    final pilots = data.scoringPilots;
    final excluded = data.nonFlyingParticipants;
    final rows = <(IconData, String, String, String, bool)>[
      if (options?.teamsEnabled ?? false)
        (
          Icons.shield_outlined,
          'Team protection',
          protection ? 'On' : 'Off',
          protection
              ? 'Teammates never fly in the same group.'
              : seeded
              ? 'Off because Seeded order is on.'
              : '',
          true,
        ),
      (
        Icons.shuffle,
        'Draw mode',
        seeded ? 'Seeded Man on Man' : 'Man on Man',
        seeded
            ? 'Only the ${options?.preliminaryRounds ?? 1} preliminary rounds '
                  'are drawn now.'
            : '',
        true,
      ),
      (
        Icons.swap_vert,
        'Back-to-back flights',
        backToBack ? 'Allowed' : 'Avoided',
        backToBack
            ? ''
            : 'No pilot flies the last group of one round and the first '
                  'group of the next.',
        true,
      ),
      (
        Icons.view_column_outlined,
        'Lane mode',
        ConfigDrift.laneModeText(options?.laneMode ?? LaneMode.none),
        options?.laneMode == LaneMode.random
            ? 'Each pilot gets a lane in every group.'
            : 'Pilots are not given lanes.',
        true,
      ),
      (
        Icons.groups_outlined,
        'Pilots in the draw',
        '$pilots scoring pilot${pilots == 1 ? '' : 's'}',
        excluded > 0
            ? '$excluded non-flying participant${excluded == 1 ? ' is' : 's are'} excluded.'
            : '',
        true,
      ),
      (
        Icons.history,
        'Configuration revision',
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
                  'From contest configuration',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  'Read-only here. Change these in Configuration.',
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
                      label: 'Change ${label.toLowerCase()} in Configuration',
                      excludeSemantics: true,
                      button: true,
                      child: TextButton.icon(
                        onPressed: onOpenConfiguration,
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Change'),
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
