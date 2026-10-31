import 'dart:math' as math;

import '../pilot_cards/card_columns.dart';
import 'scoring_sheet_options.dart';

/// What a column of the sheet holds.
enum ScoringSheetColumnId {
  lane,
  name,
  club,
  team,
  number,
  className,
  time,
  landing,
  height,
  over75,
  restart,
  penalty,
  reflight,
  validated,
}

/// Printed from the draw, written by hand, or a real tick box.
enum ScoringSheetColumnKind { printed, write, tick }

/// One column of the sheet: its heading, unit hint, kind and widths in
/// millimetres. [minMm] is the narrowest it is drawn; [targetMm] the width the
/// writing cells grow to before the pilot's name does.
class ScoringSheetColumn {
  const ScoringSheetColumn(
    this.id,
    this.title,
    this.kind,
    this.minMm,
    this.targetMm, {
    this.hint = '',
    this.centered = false,
  });

  final ScoringSheetColumnId id;

  /// The heading lines ("Over", "75 m").
  final List<String> title;
  final ScoringSheetColumnKind kind;
  final double minMm;
  final double targetMm;

  /// The unit and format under the heading ("mm:ss", "pts"); empty for none.
  final String hint;
  final bool centered;

  bool get isPrinted => kind == ScoringSheetColumnKind.printed;
  bool get isWritten => !isPrinted;
}

/// A column with the width it is drawn at.
class SizedSheetColumn {
  const SizedSheetColumn(this.column, this.width);

  final ScoringSheetColumn column;

  /// In logical pixels (96 to the inch).
  final double width;
}

/// The columns of the sheet that sit side by side on one printed page. A sheet
/// whose columns do not fit across a page continues in further strips.
class ScoringSheetStrip {
  const ScoringSheetStrip(this.columns);

  final List<SizedSheetColumn> columns;

  double get width => columns.fold(0.0, (sum, c) => sum + c.width);

  /// Where the printed columns end and the writing columns begin sits in this
  /// strip, so a heavier rule can mark it.
  int? get splitIndex {
    for (var i = 1; i < columns.length; i++) {
      if (columns[i].column.isWritten && columns[i - 1].column.isPrinted) {
        return i;
      }
    }
    return null;
  }
}

/// The columns of the Scoring Sheet and how they share a page width
/// (`plan/ui/contest-administration/reports/scoring-sheet.md`).
abstract final class ScoringSheetColumns {
  /// Millimetres to logical pixels (96 to the inch).
  static const double pxPerMm = 3.7795;

  /// The widest the pilot's name grows to.
  static const double nameMaxMm = 70;

  static const _lane = ScoringSheetColumn(
    ScoringSheetColumnId.lane,
    ['Lane'],
    ScoringSheetColumnKind.printed,
    11,
    11,
    centered: true,
  );
  static const _name = ScoringSheetColumn(
    ScoringSheetColumnId.name,
    ['Pilot'],
    ScoringSheetColumnKind.printed,
    40,
    50,
  );
  static const _club = ScoringSheetColumn(
    ScoringSheetColumnId.club,
    ['Club'],
    ScoringSheetColumnKind.printed,
    26,
    40,
  );
  static const _team = ScoringSheetColumn(
    ScoringSheetColumnId.team,
    ['Team'],
    ScoringSheetColumnKind.printed,
    24,
    32,
  );
  static const _number = ScoringSheetColumn(
    ScoringSheetColumnId.number,
    ['No.'],
    ScoringSheetColumnKind.printed,
    12,
    12,
    centered: true,
  );
  static const _class = ScoringSheetColumn(
    ScoringSheetColumnId.className,
    ['Class'],
    ScoringSheetColumnKind.printed,
    16,
    16,
  );

  /// The columns for a contest of [discipline] (`F5J`, `F3J`, ...; an unknown
  /// one counts as a duration task without height or restart), with the
  /// optional ones the options keep. Lane is first and only with [lanes]; the
  /// motor restart only when the contest [restart]s are allowed.
  static List<ScoringSheetColumn> forContest({
    required String? discipline,
    required bool lanes,
    required bool restart,
    required ScoringSheetOptions options,
  }) {
    final label = discipline?.toUpperCase();
    return [
      if (lanes) _lane,
      _name,
      if (options.showClub) _club,
      if (options.showTeam) _team,
      if (options.showNumber) _number,
      if (options.showClass) _class,
      const ScoringSheetColumn(
        ScoringSheetColumnId.time,
        ['Time'],
        ScoringSheetColumnKind.write,
        18,
        26,
        hint: 'mm:ss',
      ),
      const ScoringSheetColumn(
        ScoringSheetColumnId.landing,
        ['Landing'],
        ScoringSheetColumnKind.write,
        14,
        20,
        hint: 'pts',
      ),
      if (CardColumns.withHeight.contains(label))
        const ScoringSheetColumn(
          ScoringSheetColumnId.height,
          ['Height'],
          ScoringSheetColumnKind.write,
          14,
          20,
          hint: 'm',
        ),
      const ScoringSheetColumn(
        ScoringSheetColumnId.over75,
        ['Over', '75 m'],
        ScoringSheetColumnKind.tick,
        13,
        16,
        centered: true,
      ),
      if (restart && CardColumns.withRestart.contains(label))
        const ScoringSheetColumn(
          ScoringSheetColumnId.restart,
          ['Motor', 'restart'],
          ScoringSheetColumnKind.tick,
          13,
          16,
          centered: true,
        ),
      const ScoringSheetColumn(
        ScoringSheetColumnId.penalty,
        ['Penalty'],
        ScoringSheetColumnKind.write,
        14,
        20,
        hint: 'pts',
      ),
      const ScoringSheetColumn(
        ScoringSheetColumnId.reflight,
        ['Reflight'],
        ScoringSheetColumnKind.write,
        18,
        26,
      ),
      if (options.validated)
        const ScoringSheetColumn(
          ScoringSheetColumnId.validated,
          ['Validated'],
          ScoringSheetColumnKind.write,
          18,
          26,
        ),
    ];
  }

  /// The narrowest the columns can be drawn, in millimetres.
  static double minimumMm(List<ScoringSheetColumn> columns) =>
      columns.fold(0.0, (sum, c) => sum + c.minMm);

  /// The writing columns' width in millimetres at [strips].
  static double writingMm(List<ScoringSheetStrip> strips) =>
      strips.fold(0.0, (sum, strip) {
        return sum +
            strip.columns
                .where((c) => c.column.isWritten)
                .fold(0.0, (s, c) => s + c.width / pxPerMm);
      });

  /// Whether every column fits across [widthPx] at its narrowest.
  static bool fits(List<ScoringSheetColumn> columns, double widthPx) =>
      minimumMm(columns) * pxPerMm <= widthPx + 0.01;

  /// Shares [widthPx] among [columns]. Printed columns start at their wanted
  /// width and writing columns at their minimum; Club, Team and Pilot give up
  /// room first when it is short. Columns that cannot all fit even then are
  /// drawn at their minimum and continue in further strips, a whole column at
  /// a time. Spare width goes to the writing cells up to their target, then
  /// to the pilot's name up to [nameMaxMm].
  static List<ScoringSheetStrip> plan(
    List<ScoringSheetColumn> columns,
    double widthPx,
  ) {
    final widthMm = widthPx / pxPerMm;
    if (fits(columns, widthPx)) {
      final widths = _fill(
        columns,
        [for (final c in columns) c.isPrinted ? c.targetMm : c.minMm],
        widthMm,
        shrink: true,
      );
      return [_strip(columns, widths, widthPx)];
    }
    final strips = <List<ScoringSheetColumn>>[[]];
    var used = 0.0;
    for (final column in columns) {
      if (strips.last.isNotEmpty && used + column.minMm > widthMm + 0.01) {
        strips.add([]);
        used = 0;
      }
      strips.last.add(column);
      used += column.minMm;
    }
    return [
      for (final strip in strips)
        _strip(
          strip,
          _fill(strip, [for (final c in strip) c.minMm], widthMm),
          widthPx,
        ),
    ];
  }

  static List<double> _fill(
    List<ScoringSheetColumn> columns,
    List<double> start,
    double widthMm, {
    bool shrink = false,
  }) {
    final w = [...start];
    var spare = widthMm - w.fold(0.0, (a, b) => a + b);
    if (spare < 0 && shrink) {
      for (final id in [
        ScoringSheetColumnId.club,
        ScoringSheetColumnId.team,
        ScoringSheetColumnId.name,
      ]) {
        final i = columns.indexWhere((c) => c.id == id);
        if (i < 0) {
          continue;
        }
        final give = math.min(-spare, w[i] - columns[i].minMm);
        w[i] -= give;
        spare += give;
        if (spare >= 0) {
          break;
        }
      }
      return w;
    }
    if (spare <= 0) {
      return w;
    }
    final writing = [
      for (var i = 0; i < columns.length; i++)
        if (columns[i].isWritten) i,
    ];
    final room = writing.fold(0.0, (s, i) => s + columns[i].targetMm - w[i]);
    final grow = math.min(spare, room);
    if (room > 0) {
      for (final i in writing) {
        w[i] += grow * (columns[i].targetMm - w[i]) / room;
      }
    }
    spare -= grow;
    final name = columns.indexWhere((c) => c.id == ScoringSheetColumnId.name);
    if (name >= 0 && spare > 0) {
      final give = math.min(spare, math.max(0, nameMaxMm - w[name]));
      w[name] += give;
      spare -= give;
    }
    if (spare > 0) {
      final share = writing.isEmpty ? columns.length : writing.length;
      for (var i = 0; i < columns.length; i++) {
        if (writing.isEmpty || columns[i].isWritten) {
          w[i] += spare / share;
        }
      }
    }
    return w;
  }

  /// Turns millimetres to pixels, the last column taking the rounding so the
  /// strip is exactly [widthPx] wide.
  static ScoringSheetStrip _strip(
    List<ScoringSheetColumn> columns,
    List<double> widthsMm,
    double widthPx,
  ) {
    final sized = <SizedSheetColumn>[];
    var used = 0.0;
    for (var i = 0; i < columns.length; i++) {
      final last = i == columns.length - 1;
      final px = last
          ? widthPx - used
          : (widthsMm[i] * pxPerMm).roundToDouble();
      sized.add(SizedSheetColumn(columns[i], px));
      used += px;
    }
    return ScoringSheetStrip(sized);
  }
}
