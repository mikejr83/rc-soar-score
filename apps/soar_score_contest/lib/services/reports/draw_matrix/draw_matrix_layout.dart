import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'draw_matrix_columns.dart';
import 'draw_matrix_data.dart';
import 'draw_matrix_options.dart';
import 'draw_matrix_style.dart';

/// One row of a table on a printed page.
sealed class DrawMatrixItem {
  const DrawMatrixItem();
}

/// The heaviest mark on the sheet: where a round starts, or carries on.
final class DrawMatrixRoundRow extends DrawMatrixItem {
  const DrawMatrixRoundRow({
    required this.ordinal,
    this.continued = false,
    this.gapAbove = false,
  });

  final int ordinal;

  /// The round carries on from the column or page before.
  final bool continued;

  /// Space above it, because something sits above it in the column.
  final bool gapAbove;
}

/// Where a group starts, or carries on, with its size.
final class DrawMatrixGroupRow extends DrawMatrixItem {
  const DrawMatrixGroupRow({
    required this.label,
    required this.size,
    this.continued = false,
  });

  final String label;
  final int size;
  final bool continued;
}

/// One pilot in a group.
final class DrawMatrixPilotRow extends DrawMatrixItem {
  const DrawMatrixPilotRow({required this.pilot, required this.lines});

  final DrawMatrixPilot pilot;

  /// The most lines any column needs; sets the row's height.
  final int lines;
}

/// One printed page: one table, or two side by side in compact mode.
class DrawMatrixPage {
  const DrawMatrixPage(this.tables);

  final List<List<DrawMatrixItem>> tables;
}

/// How many lines [text] needs in a cell [width] px wide with type of
/// [fontSize] px.
typedef DrawMatrixLineCounter = int Function(
  String text,
  double width,
  double fontSize,
);

/// How the Draw Matrix splits over pages.
///
/// Rows run in order of round and group. A group is never split when it fits
/// in a column; a round header is only placed together with its first group;
/// a round that carries on repeats its header as "(continued)"; a group larger
/// than a column carries on as "(continued)". Each row is measured after
/// wrapping, so a long name pushes groups on rather than overflow.
class DrawMatrixLayout {
  DrawMatrixLayout._({
    required this.pages,
    required this.columns,
    required this.style,
    required this.tableWidth,
    required this.wrappedColumns,
  });

  /// Plans the pages of [data] for [options] in a body of [body].
  ///
  /// [lineCounter] measures wrapped text; the default sets it in the sheet's
  /// own type.
  factory DrawMatrixLayout.plan({
    required DrawMatrixData data,
    required DrawMatrixOptions options,
    required Size body,
    required bool teams,
    required bool numbers,
    required bool classes,
    DrawMatrixLineCounter? lineCounter,
    DrawMatrixTextMeter? textMeter,
  }) {
    final style = options.compact
        ? DrawMatrixStyle.compact
        : DrawMatrixStyle.normal;
    final tablesPerPage = options.compact ? 2 : 1;
    final tableWidth = options.compact
        ? ((body.width - DrawMatrixStyle.gutter) / 2).floorToDouble()
        : body.width;
    final columns = DrawMatrixColumn.plan(
      options: options,
      style: style,
      width: tableWidth,
      pilots: [
        for (final round in data.rounds)
          if (options.rounds.contains(round.ordinal))
            for (final group in round.groups) ...group.pilots,
      ],
      meter: textMeter ?? measuredWidth,
      lanes: data.hasLanes,
      teams: teams,
      numbers: numbers,
      classes: classes,
    );
    final count = lineCounter ?? measuredLines;
    final capacity = body.height - style.headHeight - 2;

    final pages = <List<List<DrawMatrixItem>>>[];
    var table = <DrawMatrixItem>[];
    var used = 0.0;

    void newTable() {
      if (pages.isEmpty || pages.last.length == tablesPerPage) {
        pages.add([]);
      }
      table = [];
      pages.last.add(table);
      used = 0;
    }

    void push(DrawMatrixItem item, double height) {
      table.add(item);
      used += height;
    }

    // Every column is measured, not only the ones expected to wrap: a cell
    // that sets taller than planned would push the page's last rows off it.
    final memo = <(String, double), int>{};
    final wrapped = <DrawMatrixColumnId>{};
    int linesOf(DrawMatrixPilot pilot) {
      var lines = 1;
      for (final column in columns) {
        final text = column.textOf(pilot);
        final cell = memo.putIfAbsent((
          text,
          column.width,
        ), () => count(text, column.width - 2 * style.padX, style.fontSize));
        if (cell > 1 && column.id != DrawMatrixColumnId.name) {
          wrapped.add(column.id);
        }
        lines = math.max(lines, cell);
      }
      return lines;
    }

    newTable();
    for (final round in data.rounds) {
      if (!options.rounds.contains(round.ordinal)) {
        continue;
      }
      for (var g = 0; g < round.groups.length; g++) {
        final group = round.groups[g];
        final rows = [
          for (final pilot in group.pilots)
            DrawMatrixPilotRow(pilot: pilot, lines: linesOf(pilot)),
        ];
        final groupHeight =
            style.groupHeight +
            rows.fold(0.0, (sum, row) => sum + style.rowHeight(row.lines));
        final roundHeight = g == 0
            ? style.roundHeight(gap: table.isNotEmpty)
            : 0.0;
        final groupRow = DrawMatrixGroupRow(
          label: group.label,
          size: group.pilots.length,
        );
        if (used + roundHeight + groupHeight > capacity && table.isNotEmpty) {
          newTable();
          if (g > 0) {
            push(
              DrawMatrixRoundRow(ordinal: round.ordinal, continued: true),
              style.roundHeight(gap: false),
            );
          }
        }
        if (g == 0) {
          final gap = table.isNotEmpty;
          push(
            DrawMatrixRoundRow(ordinal: round.ordinal, gapAbove: gap),
            style.roundHeight(gap: gap),
          );
        }
        push(groupRow, style.groupHeight);
        for (final row in rows) {
          final height = style.rowHeight(row.lines);
          if (used + height > capacity) {
            newTable();
            push(
              DrawMatrixRoundRow(ordinal: round.ordinal, continued: true),
              style.roundHeight(gap: false),
            );
            push(
              DrawMatrixGroupRow(
                label: group.label,
                size: group.pilots.length,
                continued: true,
              ),
              style.groupHeight,
            );
          }
          push(row, height);
        }
      }
    }
    return DrawMatrixLayout._(
      pages: [for (final tables in pages) DrawMatrixPage(tables)],
      columns: columns,
      style: style,
      tableWidth: tableWidth,
      wrappedColumns: wrapped,
    );
  }

  final List<DrawMatrixPage> pages;
  final List<DrawMatrixColumn> columns;
  final DrawMatrixStyle style;

  /// The width of one table.
  final double tableWidth;

  /// The columns, other than the pilot's, whose text wraps onto a second line
  /// for at least one pilot.
  final Set<DrawMatrixColumnId> wrappedColumns;

  /// The pilot column is narrower than this and a long name wraps.
  static const double comfortableName = 170;

  /// The columns ask for more room than the page has: rows wrap onto a second
  /// line, or the pilot column is squeezed. Turning a column off helps.
  bool get crowded =>
      wrappedColumns.isNotEmpty ||
      columns.firstWhere((c) => c.id == DrawMatrixColumnId.name).width <
          comfortableName;

  /// The default text meter: [text] set in the sheet's type on one line.
  static double measuredWidth(
    String text,
    double fontSize, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : null,
          fontFamilyFallback: _fonts,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  /// The default line counter: [text] set in the sheet's type, wrapped at
  /// [width] px.
  static int measuredLines(String text, double width, double fontSize) {
    if (text.isEmpty) {
      return 1;
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontFamilyFallback: _fonts),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: math.max(1, width));
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return math.max(1, lines);
  }

  static const List<String> _fonts = [
    'Noto Sans',
    'Arial',
    'Helvetica',
    'Segoe UI',
  ];
}
