import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

/// One row of a standings table.
class StandingsRow {
  const StandingsRow({
    required this.place,
    required this.name,
    required this.score,
    this.isYou = false,
    this.youLabel = '(you)',
    this.tied = false,
  });

  final String place;
  final String name;
  final String score;

  /// The viewer's own row: bold, marked with a bar and the [youLabel] text.
  final bool isYou;
  final String youLabel;
  final bool tied;
}

/// Place, name and score, with tabular right-aligned scores. The viewer's row
/// is marked by text and a leading bar, not by colour alone.
class StandingsTable extends StatelessWidget {
  const StandingsTable({
    required this.nameHeader,
    required this.rows,
    super.key,
  });

  final String nameHeader;
  final List<StandingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final head = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final cell = theme.textTheme.bodyLarge;
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(56),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Place', style: head),
            ),
            Text(nameHeader, style: head),
            Text('Score', style: head, textAlign: TextAlign.right),
          ],
        ),
        for (final row in rows)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            children: [
              _padded(
                Text(
                  row.place,
                  style: _style(cell, row).merge(BrandTypography.numbers),
                ),
                row,
                scheme,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(row.name, style: _style(cell, row)),
                    if (row.isYou)
                      Text(
                        row.youLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (row.tied)
                      Icon(
                        Icons.link,
                        size: 16,
                        semanticLabel: 'Tie',
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  row.score,
                  textAlign: TextAlign.right,
                  style: _style(cell, row).merge(BrandTypography.numbers),
                ),
              ),
            ],
          ),
      ],
    );
  }

  TextStyle _style(TextStyle? base, StandingsRow row) =>
      (base ?? const TextStyle()).copyWith(
        fontWeight: row.isYou ? FontWeight.w700 : null,
      );

  Widget _padded(Widget child, StandingsRow row, ColorScheme scheme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        if (row.isYou)
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            color: scheme.onSurface,
          ),
        child,
      ],
    ),
  );
}
