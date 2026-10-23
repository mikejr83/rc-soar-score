import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../models/group_result_row.dart';
import 'status_chip.dart';

/// One pilot's flight in the group results: name and number, a reason chip
/// when the flight is zero, unscored or under review, then time and score.
/// The viewer's row carries a star, "(you)" and a leading bar.
class GroupResultTile extends StatelessWidget {
  const GroupResultTile({required this.row, super.key});

  final GroupResultRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final emphasis = row.isYou ? FontWeight.w700 : FontWeight.w600;
    final chip = switch (row.kind) {
      GroupRowKind.scored => null,
      GroupRowKind.zero => StatusChip(
        label: 'Zero: ${row.zeroReason}',
        icon: Icons.location_off_outlined,
        style: StatusChipStyle.tonal,
      ),
      GroupRowKind.noScore => const StatusChip(
        label: 'No score yet',
        icon: Icons.schedule,
        style: StatusChipStyle.quiet,
      ),
      GroupRowKind.pendingReview => const StatusChip(
        label: 'Pending review',
        icon: Icons.rate_review_outlined,
      ),
    };
    final note = switch (row.kind) {
      GroupRowKind.scored => row.detail,
      GroupRowKind.zero => 'Time, height and landing are zeroed.',
      GroupRowKind.noScore => 'Not in the standings for this round.',
      GroupRowKind.pendingReview =>
        'Showing the original entry: ${row.detail}.',
    };
    final numbers = BrandTypography.numbers.copyWith(
      fontWeight: row.isYou ? FontWeight.w700 : null,
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
          left: row.isYou
              ? BorderSide(color: scheme.onSurface, width: 4)
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.fromLTRB(row.isYou ? 8 : 0, 10, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    if (row.isYou) const Icon(Icons.star_outline, size: 18),
                    Text(
                      row.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: emphasis,
                      ),
                    ),
                    if (row.isYou)
                      Text(
                        '(you)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Text(
                        'Pilot ${row.pilotNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                  ],
                ),
                if (chip != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: chip,
                  ),
                if (note != null)
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              row.time ?? '–',
              textAlign: TextAlign.right,
              style: numbers,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              row.score ?? '–',
              textAlign: TextAlign.right,
              style: numbers,
            ),
          ),
        ],
      ),
    );
  }
}
