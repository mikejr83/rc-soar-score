import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_en.dart';
import '../../../services/reports/standings/standings_layout.dart';
import '../../../services/reports/standings/standings_table.dart';
import '../viewer/paper_style.dart';

final AppLocalizations _fallbackL10n = AppLocalizationsEn();

AppLocalizations _l10nOf(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    _fallbackL10n;

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

  List<_Column> _columns(AppLocalizations l10n) {
    final options = table.options;
    final first = page.isFirstSet;
    return [
      _Column(l10n.standingsColRank, StandingsLayout.rankWidth, TextAlign.right),
      _Column(l10n.standingsColPilot, StandingsLayout.nameWidth, TextAlign.left),
      if (first)
        _Column(l10n.standingsColTotal, StandingsLayout.totalWidth, TextAlign.right),
      if (first && options.percentage)
        _Column(
          l10n.standingsColPct,
          StandingsLayout.percentageWidth,
          TextAlign.right,
          semantic: l10n.standingsColPctSemantic,
        ),
      if (first && options.raw)
        _Column(
          l10n.standingsColRaw,
          StandingsLayout.rawWidth,
          TextAlign.right,
          semantic: l10n.standingsColRawSemantic,
        ),
      if (first && options.team)
        _Column(l10n.standingsColTeam, StandingsLayout.teamWidth, TextAlign.left),
      if (first && options.number)
        _Column(
          l10n.standingsColNo,
          StandingsLayout.numberWidth,
          TextAlign.right,
          semantic: l10n.standingsColNoSemantic,
        ),
      if (first && options.pilotClass)
        _Column(l10n.standingsColClass, StandingsLayout.classWidth, TextAlign.left),
      if (options.details)
        _Column(
          '',
          StandingsLayout.labelWidth,
          TextAlign.left,
          semantic: l10n.standingsColLineSemantic,
        ),
      for (final round in page.rounds)
        _Column(
          partialRounds.containsKey(round)
              ? l10n.standingsRoundColumnPartial(round)
              : l10n.standingsRoundColumn(round),
          StandingsLayout.roundWidth,
          TextAlign.right,
          sub: partialRounds[round],
          rule: true,
          semantic: l10n.standingsRoundSemantic(round),
        ),
      if (page.penalty)
        _Column(
          l10n.standingsColPenalty,
          StandingsLayout.roundWidth,
          TextAlign.right,
          sub: l10n.standingsPenaltySub,
          rule: true,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10nOf(context);
    final columns = _columns(l10n);
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
      container: true,
      role: SemanticsRole.table,
      label: l10n.standingsTableSemantics(page.number),
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
                container: true,
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
    final l10n = _l10nOf(context);
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
      ..add(
        cell(
          '${row.place}',
          bold: true,
          label: l10n.standingsRankCell(row.place),
        ),
      )
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
      cells.add(cell(l10n.standingsScoreCell, lines: table.detailLabels));
    }
    for (final round in page.rounds) {
      final value = row.cells[round];
      final score = value?.score;
      if (score == null) {
        cells.add(cell('—', label: l10n.standingsNoScore));
        continue;
      }
      final text = format.round(score);
      final dropped = value!.dropped;
      cells.add(
        cell(
          dropped ? '*$text' : text,
          fill: dropped ? PaperStyle.dropShade : null,
          label: dropped ? l10n.standingsDroppedLabel(text) : text,
          lines: details ? table.detailLines(value.detail) : const [],
        ),
      );
    }
    if (page.penalty) {
      cells.add(cell(row.penalty > 0 ? format.penalty(row.penalty) : ''));
    }
    return Semantics(
      container: true,
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
  Widget build(BuildContext context) {
    final l10n = _l10nOf(context);
    return Semantics(
    label: l10n.standingsReviewChipSemantic,
    child: ExcludeSemantics(
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF9E9E9E)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.desktop_windows,
              size: 8,
              color: Color(0xFF616161),
            ),
            const SizedBox(width: 2),
            Text(
              l10n.standingsReviewChip,
              softWrap: false,
              style: const TextStyle(fontSize: 8, color: Color(0xFF616161)),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
