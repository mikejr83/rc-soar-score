import 'dart:math' as math;

import 'draw_matrix_data.dart';
import 'draw_matrix_options.dart';
import 'draw_matrix_style.dart';

/// The columns the Draw Matrix can carry, in table order.
enum DrawMatrixColumnId {
  lane,
  name,
  team,
  number,
  className,
  club,
  fai,
  national,
}

/// How wide [text] sets in the sheet's type at [fontSize] px.
typedef DrawMatrixTextMeter = double Function(
  String text,
  double fontSize, {
  bool bold,
});

/// One column of the table: its heading, width and how its text sits.
class DrawMatrixColumn {
  const DrawMatrixColumn({
    required this.id,
    required this.title,
    required this.width,
    required this.alignRight,
    required this.wraps,
  });

  final DrawMatrixColumnId id;
  final String title;
  final double width;
  final bool alignRight;

  /// Text may run to more than one line.
  final bool wraps;

  /// What [pilot] shows in this column; empty when they have no value.
  String textOf(DrawMatrixPilot pilot) => switch (id) {
    DrawMatrixColumnId.lane => pilot.lane?.toString() ?? '',
    DrawMatrixColumnId.name => pilot.name,
    DrawMatrixColumnId.team => pilot.team ?? '',
    DrawMatrixColumnId.number => pilot.number?.toString() ?? '',
    DrawMatrixColumnId.className => pilot.className ?? '',
    DrawMatrixColumnId.club => pilot.club ?? '',
    DrawMatrixColumnId.fai => pilot.faiId ?? '',
    DrawMatrixColumnId.national => pilot.nationalId ?? '',
  };

  /// The room the pilot column keeps however much the others ask for.
  static const double minNameWidth = 140;

  /// The least a team or club column is squeezed to before the pilot column
  /// gives way.
  static const double minWrapWidth = 64;

  /// Chooses the columns for a table [width] px wide. A column that does not
  /// apply is left out.
  ///
  /// Every column but the pilot's shrinks to fit its widest value (or its
  /// heading) in [pilots], so a class like "Sportsman" never wraps; the pilot
  /// column takes everything that is left. Team and club stop at a widest
  /// useful size and wrap past it. If the others leave the pilot column less
  /// than [minNameWidth], team and club give way first.
  static List<DrawMatrixColumn> plan({
    required DrawMatrixOptions options,
    required DrawMatrixStyle style,
    required double width,
    required Iterable<DrawMatrixPilot> pilots,
    required DrawMatrixTextMeter meter,
    required bool lanes,
    required bool teams,
    required bool numbers,
    required bool classes,
  }) {
    final titles = <DrawMatrixColumnId, String>{
      if (lanes) DrawMatrixColumnId.lane: 'Lane',
      DrawMatrixColumnId.name: 'Pilot',
      if (teams) DrawMatrixColumnId.team: 'Team',
      if (numbers) DrawMatrixColumnId.number: 'No.',
      if (classes) DrawMatrixColumnId.className: 'Class',
      if (options.showClub) DrawMatrixColumnId.club: 'Club',
      if (options.showFai) DrawMatrixColumnId.fai: 'FAI ID',
      if (options.showNational) DrawMatrixColumnId.national: 'National ID',
    };
    // The columns that may wrap past a widest useful size.
    final caps = {
      DrawMatrixColumnId.team: style.teamFixed ?? style.teamMax,
      DrawMatrixColumnId.club: style.clubMax,
    };
    DrawMatrixColumn shell(DrawMatrixColumnId id, {double w = 0}) =>
        DrawMatrixColumn(
          id: id,
          title: titles[id]!,
          width: w,
          alignRight:
              id == DrawMatrixColumnId.lane || id == DrawMatrixColumnId.number,
          wraps: id == DrawMatrixColumnId.name || caps.containsKey(id),
        );

    final widths = <DrawMatrixColumnId, double>{};
    for (final id in titles.keys) {
      if (id == DrawMatrixColumnId.name) {
        continue;
      }
      final column = shell(id);
      var widest = meter(column.title, style.headFont, bold: true);
      final seen = <String>{};
      for (final pilot in pilots) {
        final text = column.textOf(pilot);
        if (text.isNotEmpty && seen.add(text)) {
          widest = math.max(
            widest,
            meter(text, style.fontSize, bold: id == DrawMatrixColumnId.lane),
          );
        }
      }
      // A little slack so a rounding difference never wraps the last letter.
      final fit = (widest + 2 * style.padX + 2).ceilToDouble();
      widths[id] = caps[id] == null ? fit : math.min(fit, caps[id]!);
    }

    var others = widths.values.fold(0.0, (a, b) => a + b);
    var shortfall = minNameWidth - (width - others);
    for (final id in caps.keys) {
      if (shortfall <= 0 || !widths.containsKey(id)) {
        continue;
      }
      final give = math.min(shortfall, math.max(0, widths[id]! - minWrapWidth));
      widths[id] = widths[id]! - give;
      shortfall -= give;
    }
    others = widths.values.fold(0.0, (a, b) => a + b);
    widths[DrawMatrixColumnId.name] = math.max(0, width - others);

    return [for (final id in titles.keys) shell(id, w: widths[id]!)];
  }
}
