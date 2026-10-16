import 'package:flutter/material.dart';

/// How a pilot row is laid out for the width it has.
enum ScoreGridMode {
  /// One line per pilot under a shared column heading.
  wide,

  /// Three lines per pilot, with the column labels in the cells.
  medium,

  /// A stacked card per pilot.
  compact;

  static const double wideMin = 1130;
  static const double mediumMin = 600;

  static ScoreGridMode of(double width) {
    if (width >= wideMin) return wide;
    if (width >= mediumMin) return medium;
    return compact;
  }
}

/// The column widths of the wide score table (`Scoring Screen.dc.html`). The
/// heading and every pilot row use these, so the columns line up.
abstract final class ScoreGridColumns {
  static const double lane = 48;
  static const double time = 116;
  static const double height = 96;
  static const double land = 120;
  static const double raw = 72;
  static const double group = 80;
  static const double pen = 108;
  static const double ind = 84;
  static const double stat = 132;
  static const double menu = 44;

  /// The pilot column's least width; it takes the rest.
  static const double pilotMin = 150;

  static const double gap = 6;
  static const double rowPadding = 8;
}

/// The sticky column headings of the wide table: a name over its unit.
class ScoreGridHeader extends StatelessWidget {
  const ScoreGridHeader({super.key, this.showHeight = true});

  final bool showHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.35,
    );
    Widget cell(
      String title,
      String unit,
      double? width, {
      TextAlign align = TextAlign.start,
    }) {
      final child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: align == TextAlign.end
              ? CrossAxisAlignment.end
              : align == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: small?.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
            if (unit.isNotEmpty) Text(unit, style: small),
          ],
        ),
      );
      return width == null
          ? Expanded(child: child)
          : SizedBox(width: width, child: child);
    }

    const gap = SizedBox(width: ScoreGridColumns.gap);
    return Container(
      key: const ValueKey('score-grid-header'),
      padding: const EdgeInsets.symmetric(
        horizontal: ScoreGridColumns.rowPadding,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell('Lane', '', ScoreGridColumns.lane, align: TextAlign.center),
          gap,
          cell('Pilot · team', '', null),
          gap,
          cell('Time flown', 'm:ss', ScoreGridColumns.time),
          gap,
          if (showHeight) ...[
            cell('Launch height', 'metres', ScoreGridColumns.height),
            gap,
          ],
          cell('Landing · flags', '', ScoreGridColumns.land),
          gap,
          cell(
            'Raw score',
            'points',
            ScoreGridColumns.raw,
            align: TextAlign.end,
          ),
          gap,
          cell(
            'Group score',
            'of 1000',
            ScoreGridColumns.group,
            align: TextAlign.end,
          ),
          gap,
          cell('Penalties', 'flight · cumulative', ScoreGridColumns.pen),
          gap,
          cell('Indicators', 'source · review', ScoreGridColumns.ind),
          gap,
          cell('Status', 'official · lock', ScoreGridColumns.stat),
          gap,
          const SizedBox(width: ScoreGridColumns.menu),
        ],
      ),
    );
  }
}
