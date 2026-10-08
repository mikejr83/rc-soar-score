import 'package:flutter/material.dart';

import '../../services/matrix/draw_form_check.dart';
import 'matrix_colors.dart';

/// The group sizes the typed numbers would give, with the team-protection
/// minimum and the seeded note.
class GroupSizePreview extends StatelessWidget {
  const GroupSizePreview({
    super.key,
    required this.check,
    required this.pilots,
    this.minimumGroups = 0,
    this.largestTeam,
    this.seededRounds,
  });

  final DrawFormCheck check;
  final int pilots;

  /// The team-protection minimum number of groups; 0 when it is off.
  final int minimumGroups;
  final String? largestTeam;

  /// Set for Seeded Man on Man: how many preliminary rounds are drawn now.
  final int? seededRounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final sizes = check.sizes;
    final groups = check.groups;
    final title = sizes.isNotEmpty
        ? '${sizes.length} group${sizes.length == 1 ? '' : 's'}: '
              '${sizes.join(', ')} pilot${sizes.length == 1 && sizes.first == 1 ? '' : 's'}'
        : groups != null && groups > pilots
        ? 'More groups than scoring pilots'
        : 'Enter groups per round to see the group sizes.';
    Widget note(IconData icon, Color color, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text(
                title,
                key: const ValueKey('group-preview-title'),
                style: theme.textTheme.titleSmall,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < sizes.length; i++)
                    Container(
                      constraints: const BoxConstraints(minWidth: 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sizes[i] < 2
                              ? colors.warn
                              : scheme.outlineVariant,
                          width: sizes[i] < 2 ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Group ${DrawFormCheck.groupLetter(i)}',
                                style: theme.textTheme.labelMedium,
                              ),
                              if (sizes[i] < 2) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.warning_amber,
                                  size: 14,
                                  color: colors.warn,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${sizes[i]} pilot${sizes[i] == 1 ? '' : 's'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (minimumGroups > 0)
                note(
                  Icons.shield_outlined,
                  groups != null && groups < minimumGroups
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                  'Minimum $minimumGroups groups. Team protection keeps '
                  'teammates apart, and the largest team'
                  '${largestTeam == null ? '' : ' ($largestTeam)'} has '
                  '$minimumGroups scoring pilots.',
                ),
              if (seededRounds != null)
                note(
                  Icons.info_outline,
                  scheme.onSurfaceVariant,
                  'Seeded Man on Man: only the $seededRounds preliminary '
                  'rounds are drawn now. Seeded rounds are drawn later from '
                  'the preliminary results.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
