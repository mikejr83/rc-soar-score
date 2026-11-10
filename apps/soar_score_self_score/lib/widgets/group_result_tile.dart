import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../models/group_result_row.dart';
import 'status_chip.dart';

/// The widths of the group-results columns, shared by the header row and each
/// [GroupResultTile] so the columns line up.
class GroupResultColumns {
  const GroupResultColumns();

  static const double time = 56;
  static const double height = 44;
  static const double landing = 64;
  static const double raw = 52;
  static const double score = 48;
}

/// One pilot's flight in the group results: name and number, a reason chip
/// when the flight is zero, unscored or under review, then the columns that
/// make up the score. The viewer's row carries a star, "(you)" and a leading
/// bar.
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
      GroupRowKind.scored =>
        row.isEstimate ? 'This score is an estimate.' : null,
      GroupRowKind.zero => 'Time, height and landing are zeroed.',
      GroupRowKind.noScore => 'Not in the standings for this round.',
      GroupRowKind.pendingReview => 'The review keeps the original entry.',
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
                        row.pilotNumber == null
                            ? ''
                            : 'Pilot ${row.pilotNumber}',
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
          const SizedBox(width: 8),
          _Cell(GroupResultColumns.time, row.time, numbers),
          _Cell(
            GroupResultColumns.height,
            row.height == null ? null : '${row.height} m',
            numbers,
          ),
          _Cell(GroupResultColumns.landing, row.landing, numbers),
          _Cell(GroupResultColumns.raw, row.rawScore, numbers),
          _Cell(GroupResultColumns.score, row.score, numbers),
        ],
      ),
    );
  }
}

/// One value under a column heading; a dash when the value is absent.
class _Cell extends StatelessWidget {
  const _Cell(this.width, this.value, this.style);

  final double width;
  final String? value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value ?? '–',
        textAlign: TextAlign.right,
        style: style,
      ),
    );
  }
}
