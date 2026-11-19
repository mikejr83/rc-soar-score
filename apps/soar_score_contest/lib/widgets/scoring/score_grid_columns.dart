import 'package:flutter/material.dart';

import '../../services/scoring/score_grid_options.dart';

/// How a pilot row is laid out for the width it has.
enum ScoreGridMode {
  /// One line per pilot under a shared column heading.
  wide,

  /// Three lines per pilot, with the column labels in the cells.
  medium,

  /// A stacked card per pilot.
  compact;

  static const double wideMin = 1140;

  /// The medium layout starts at 660 px, the grid width of a portrait tablet
  /// (768 px less the rail, its divider and the page padding is 663). From
  /// [mediumDesign] up the columns have the design's widths; below it the
  /// time, height and landing columns give up width ([MediumColumns]).
  static const double mediumMin = 660;
  static const double mediumDesign = 700;

  static ScoreGridMode of(double width) {
    if (width >= wideMin) return wide;
    if (width >= mediumMin) return medium;
    return compact;
  }
}

/// The right block of the medium table (two lines per pilot), shared by both
/// lines: the time, height and landing columns and the row menu. They have the
/// design's widths from [ScoreGridMode.mediumDesign] up and shrink evenly to
/// their least at [ScoreGridMode.mediumMin].
class MediumColumns {
  const MediumColumns._(this.time, this.height, this.land);

  /// The design's widths.
  static const MediumColumns design = MediumColumns._(120, 104, 136);

  /// The least widths, at [ScoreGridMode.mediumMin].
  static const MediumColumns least = MediumColumns._(108, 92, 124);

  factory MediumColumns.of(double width) {
    final t =
        ((width - ScoreGridMode.mediumMin) /
                (ScoreGridMode.mediumDesign - ScoreGridMode.mediumMin))
            .clamp(0.0, 1.0);
    double lerp(double a, double b) => a + (b - a) * t;
    return MediumColumns._(
      lerp(least.time, design.time),
      lerp(least.height, design.height),
      lerp(least.land, design.land),
    );
  }

  static const double lane = 44;
  static const double menu = 44;

  final double time;
  final double height;
  final double land;

  /// The width of the right block with its gaps (time, height, landing, menu
  /// and the gap before each).
  double get right => time + height + land + menu + ScoreGridColumns.gap * 4;
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
  static const double ind = 92;
  static const double stat = 132;
  static const double menu = 44;

  /// The pilot column's least width; it takes the rest.
  static const double pilotMin = 150;

  static const double gap = 6;
  static const double rowPadding = 8;

  /// The width the wide table needs for its fixed columns, a lane or number
  /// column, the pilot column at its least, the gaps and the row padding.
  /// [ScoreGridMode.wideMin] must not be below it, or the pilot column would
  /// shrink under [pilotMin].
  static const double wideNeeds =
      lane +
      pilotMin +
      time +
      height +
      land +
      raw +
      group +
      pen +
      ind +
      stat +
      menu +
      gap * 10 +
      rowPadding * 2;
}

/// The column headings of the wide and the medium table: a name over its
/// unit. The medium table only heads the first line of each row (pilot, time,
/// height, landing); the second line's cells carry their own labels.
class ScoreGridHeader extends StatelessWidget {
  const ScoreGridHeader({
    super.key,
    this.mode = ScoreGridMode.wide,
    this.medium = MediumColumns.design,
    this.showHeight = true,
    this.options = const ScoreGridOptions(),
  });

  final ScoreGridMode mode;

  /// The medium table's right block, for the width the page has.
  final MediumColumns medium;
  final bool showHeight;
  final ScoreGridOptions options;

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
              textAlign: align,
              style: small?.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
            if (unit.isNotEmpty) Text(unit, textAlign: align, style: small),
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
          if (options.showId) ...[
            cell(
              options.idLabel!,
              '',
              mode == ScoreGridMode.medium
                  ? MediumColumns.lane
                  : ScoreGridColumns.lane,
              align: TextAlign.center,
            ),
            gap,
          ],
          cell(options.showTeams ? 'Pilot · team' : 'Pilot', '', null),
          gap,
          if (mode == ScoreGridMode.medium) ...[
            cell('Time flown', 'm:ss', medium.time),
            gap,
            if (showHeight) ...[
              cell('Launch height', 'metres', medium.height),
              gap,
            ],
            cell('Landing · flags', 'points', medium.land),
            gap,
            const SizedBox(width: MediumColumns.menu),
          ] else ...[
            cell('Time flown', 'm:ss', ScoreGridColumns.time),
            gap,
            if (showHeight) ...[
              cell('Launch height', 'metres', ScoreGridColumns.height),
              gap,
            ],
            cell('Landing · flags', 'points', ScoreGridColumns.land),
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
            cell(
              'Penalties',
              'flight · cumulative',
              ScoreGridColumns.pen,
              align: TextAlign.center,
            ),
            gap,
            cell('Indicators', 'source · review', ScoreGridColumns.ind),
            gap,
            cell('Status', 'official · lock', ScoreGridColumns.stat),
            gap,
            const SizedBox(width: ScoreGridColumns.menu),
          ],
        ],
      ),
    );
  }
}
