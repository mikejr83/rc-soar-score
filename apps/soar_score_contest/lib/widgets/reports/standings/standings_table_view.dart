import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../services/reports/standings/standings_layout.dart';
import '../../../services/reports/standings/standings_table.dart';
import '../viewer/paper_style.dart';

/// One printed page of the standings table: the column heads and the rows of
/// the page's pilots, for the page's set of columns.
///
/// Columns have fixed widths, so the grid is a regular matrix. A dropped round
/// is shaded and starts with an asterisk, so a printer that drops light fills
/// loses nothing. No score is an em dash, never a blank and never a 0.
class StandingsTableView extends StatelessWidget {
  const StandingsTableView({
    super.key,
    required this.table,
    required this.page,
    required this.format,
    required this.partialRounds,
    required this.preview,
  });

  final StandingsTable table;
  final StandingsPageSpec page;
  final StandingsFormat format;

  /// Partly scored rounds by ordinal, with the "27 of 30 scored" line.
  final Map<int, String> partialRounds;

  /// Print preview hides what exists only on screen.
  final bool preview;

  static const _rule = Color(0xFFBDBDBD);

  List<_Column> get _columns {
    final options = table.options;
    final first = page.isFirstSet;
    return [
      const _Column('Rank', StandingsLayout.rankWidth, TextAlign.right),
      const _Column('Pilot', StandingsLayout.nameWidth, TextAlign.left),
      if (first)
        const _Column('Total', StandingsLayout.totalWidth, TextAlign.right),
      if (first && options.percentage)
        const _Column(
          'Pct',
          StandingsLayout.percentageWidth,
          TextAlign.right,
          semantic: 'Percentage of winner',
        ),
      if (first && options.raw)
        const _Column(
          'Raw',
          StandingsLayout.rawWidth,
          TextAlign.right,
          semantic: 'Raw score',
        ),
      if (first && options.team)
        const _Column('Team', StandingsLayout.teamWidth, TextAlign.left),
      if (first && options.number)
        const _Column(
          'No.',
          StandingsLayout.numberWidth,
          TextAlign.right,
          semantic: 'Pilot number',
        ),
      if (first && options.pilotClass)
        const _Column('Class', StandingsLayout.classWidth, TextAlign.left),
      if (options.details)
        const _Column(
          '',
          StandingsLayout.labelWidth,
          TextAlign.left,
          semantic: 'Line',
        ),
      for (final round in page.rounds)
        _Column(
          partialRounds.containsKey(round) ? 'R$round partial' : 'R$round',
          StandingsLayout.roundWidth,
          TextAlign.right,
          sub: partialRounds[round],
          rule: true,
          semantic: 'Round $round',
        ),
      if (page.penalty)
        const _Column(
          'Penalty',
          StandingsLayout.roundWidth,
          TextAlign.right,
          sub: 'Deducted from total; not dropped',
          rule: true,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    final rows = table.rows.sublist(page.pilotStart, page.pilotEnd);
    final details = table.options.details;
    final rowHeight = details
        ? (table.isF3j
              ? StandingsLayout.detailRowF3j
              : StandingsLayout.detailRowF5j)
        : StandingsLayout.plainRow;
    final width = columns.fold<double>(0, (sum, c) => sum + c.width);
    final tall = partialRounds.keys.any(page.rounds.contains) || page.penalty;
    return Semantics(
      role: SemanticsRole.table,
      label: 'Overall Results, page ${page.number}',
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 11,
          height: 14 / 11,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                role: SemanticsRole.row,
                child: Row(
                  children: [
                    for (final column in columns)
                      _HeadCell(column: column, tall: tall),
                  ],
                ),
              ),
              for (final row in rows)
                _RowView(
                  row: row,
                  columns: columns,
                  page: page,
                  table: table,
                  format: format,
                  height: rowHeight,
                  preview: preview,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Column {
  const _Column(
    this.title,
    this.width,
    this.align, {
    this.sub,
    this.rule = false,
    this.semantic,
  });

  final String title;
  final double width;
  final TextAlign align;
  final String? sub;
  final bool rule;
  final String? semantic;
}

class _HeadCell extends StatelessWidget {
  const _HeadCell({required this.column, required this.tall});

  final _Column column;
  final bool tall;

  @override
  Widget build(BuildContext context) => Semantics(
    role: SemanticsRole.columnHeader,
    label: column.semantic ?? column.title,
    child: ExcludeSemantics(
      child: Container(
        width: column.width,
        height: tall ? StandingsLayout.headRowTall : StandingsLayout.headRow,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(width: 1.5, color: PaperStyle.ink),
            left: column.rule
                ? const BorderSide(color: StandingsTableView._rule)
                : BorderSide.none,
          ),
        ),
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: column.align == TextAlign.right
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                column.title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (column.sub != null)
                Text(
                  column.sub!,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  textAlign: column.align,
                  style: const TextStyle(
                    fontSize: 8,
                    height: 10 / 8,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RowView extends StatelessWidget {
  const _RowView({
    required this.row,
    required this.columns,
    required this.page,
    required this.table,
    required this.format,
    required this.height,
    required this.preview,
  });

  final StandingsRow row;
  final List<_Column> columns;
  final StandingsPageSpec page;
  final StandingsTable table;
  final StandingsFormat format;
  final double height;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final options = table.options;
    final details = options.details;
    // Each pilot is a block; with details a black rule sets blocks apart.
    final top = details ? PaperStyle.ink : StandingsTableView._rule;
    final cells = <Widget>[];
    var index = 0;

    Widget cell(
      String text, {
      bool bold = false,
      Color? fill,
      String? label,
      SemanticsRole role = SemanticsRole.cell,
      List<String> lines = const [],
      Widget? trailing,
    }) {
      final column = columns[index++];
      final align = column.align == TextAlign.right
          ? Alignment.topRight
          : Alignment.topLeft;
      return Semantics(
        role: role,
        label: label ?? text,
        child: ExcludeSemantics(
          child: Container(
            width: column.width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: fill,
              border: Border(
                top: BorderSide(color: top),
                left: column.rule
                    ? const BorderSide(color: StandingsTableView._rule)
                    : BorderSide.none,
              ),
            ),
            alignment: align,
            child: ClipRect(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: column.align == TextAlign.right
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontWeight: bold ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (lines.isNotEmpty)
                    Text(
                      lines.join('\n'),
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 9,
                        height: 11 / 9,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    cells
      ..add(cell('${row.place}', bold: true, label: 'Rank ${row.place}'))
      ..add(
        cell(
          row.pilot.listName,
          role: SemanticsRole.cell,
          trailing: row.reviewOpen && !preview ? const _ReviewChip() : null,
        ),
      );
    if (page.isFirstSet) {
      cells.add(cell(format.score(row.total), bold: true));
      if (options.percentage) {
        cells.add(cell(format.percentage(row.percentage)));
      }
      if (options.raw) {
        cells.add(cell(format.score(row.raw)));
      }
      if (options.team) {
        cells.add(cell(row.pilot.team ?? '—'));
      }
      if (options.number) {
        cells.add(cell(row.pilot.number?.toString() ?? '—'));
      }
      if (options.pilotClass) {
        cells.add(cell(row.pilot.className ?? '—'));
      }
    }
    if (details) {
      cells.add(cell('Score', lines: table.detailLabels));
    }
    for (final round in page.rounds) {
      final value = row.cells[round];
      final score = value?.score;
      if (score == null) {
        cells.add(cell('—', label: 'no score'));
        continue;
      }
      final text = format.round(score);
      final dropped = value!.dropped;
      cells.add(
        cell(
          dropped ? '*$text' : text,
          fill: dropped ? PaperStyle.dropShade : null,
          label: dropped ? 'Dropped round, $text' : text,
          lines: details ? table.detailLines(value.detail) : const [],
        ),
      );
    }
    if (page.penalty) {
      cells.add(cell(row.penalty > 0 ? format.penalty(row.penalty) : ''));
    }
    return Semantics(
      role: SemanticsRole.row,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells),
    );
  }
}

/// A small screen-only chip beside a pilot with a score under review. It is
/// left out of print preview and the printout.
class _ReviewChip extends StatelessWidget {
  const _ReviewChip();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Screen only. Review open.',
    child: ExcludeSemantics(
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF9E9E9E)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.desktop_windows, size: 8, color: Color(0xFF616161)),
            SizedBox(width: 2),
            Text(
              'Review',
              softWrap: false,
              style: TextStyle(fontSize: 8, color: Color(0xFF616161)),
            ),
          ],
        ),
      ),
    ),
  );
}
