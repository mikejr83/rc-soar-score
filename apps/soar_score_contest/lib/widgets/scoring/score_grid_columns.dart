import 'package:flutter/material.dart';

/// The column widths of the wide score grid. The heading and every pilot row
/// use these, so the columns line up down the page.
abstract final class ScoreGridColumns {
  /// Below this width a row becomes a stacked card.
  static const double wideBreakpoint = 840;

  static const double lane = 52;
  static const double time = 150;
  static const double height = 130;
  static const double raw = 110;
  static const double group = 80;
  static const double penalty = 120;
  static const double status = 270;

  /// The gap after the time and height fields.
  static const double gap = 8;

  /// Space left of the first column: card margin, border and padding.
  static const double inset = 12 + 2 + 12;
}

/// The column headings above the pilot rows, on wide windows.
class ScoreGridHeader extends StatelessWidget {
  const ScoreGridHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    Widget cell(String text, double width) => SizedBox(
      width: width,
      child: Text(text, style: style),
    );
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ScoreGridColumns.inset,
          vertical: 8,
        ),
        child: Row(
          children: [
            cell('Lane', ScoreGridColumns.lane),
            Expanded(child: Text('Pilot', style: style)),
            cell('Time', ScoreGridColumns.time + ScoreGridColumns.gap),
            cell('Height', ScoreGridColumns.height + ScoreGridColumns.gap),
            cell('Raw', ScoreGridColumns.raw),
            cell('Group', ScoreGridColumns.group),
            cell('Penalty', ScoreGridColumns.penalty),
            cell('Status', ScoreGridColumns.status),
          ],
        ),
      ),
    );
  }
}
