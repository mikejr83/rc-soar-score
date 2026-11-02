import 'package:flutter/material.dart';

import '../../../services/reports/pilot_cards/card_columns.dart';
import '../../../services/reports/pilot_cards/pilot_cards_data.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_columns.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_layout.dart';
import '../viewer/paper_style.dart';

/// One table of the Scoring Sheet: the column headings, then the round, group
/// and pilot rows of a page. Black and white, ruled on every cell edge, with
/// no fills except the light grey behind scores Pre-fill printed; those are
/// also set in bold monospace, so a printer that drops grey loses nothing.
///
/// The rows are real table semantics: round and group rows are headers, the
/// pilot name is the row header.
class ScoringSheetTableView extends StatelessWidget {
  const ScoringSheetTableView({
    super.key,
    required this.page,
    required this.workingTime,
    required this.label,
    this.prefilled = false,
  });

  final ScoringSheetPage page;
  final String workingTime;

  /// Names the table for a screen reader ("Page 2").
  final String label;

  /// Entered scores are printed in the score cells (Pre-fill is on).
  final bool prefilled;

  static const _mono = [
    'Noto Sans Mono',
    'Consolas',
    'Courier New',
    'monospace',
  ];

  List<SizedSheetColumn> get _columns => page.strip.columns;

  TextStyle _text(double size, double line, {FontWeight? weight}) =>
      PaperStyle.body.copyWith(
        fontSize: size,
        height: line / size,
        fontWeight: weight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: prefilled
        ? '$label. Scores already entered are printed in the score cells; '
              'the other score cells are blank for officials to write in.'
        : '$label. Score cells are blank for officials to write in.',
    child: SizedBox(
      width: page.strip.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_headings(), for (final item in page.items) _row(item)],
      ),
    ),
  );

  Widget _headings() {
    final strip = page.strip;
    final split = strip.splitIndex;
    return Container(
      height: ScoringSheetStyle.columnHeadHeight,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: PaperStyle.ink),
          bottom: BorderSide(color: PaperStyle.ink, width: 2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _columns.length; i++)
            _cell(
              _columns[i].width,
              height: ScoringSheetStyle.columnHeadHeight - 3,
              first: i == 0,
              last: i == _columns.length - 1,
              heavy: i == split,
              bottom: false,
              alignment:
                  _columns[i].column.centered || _columns[i].column.isWritten
                  ? Alignment.center
                  : Alignment.centerLeft,
              child: _heading(_columns[i].column),
            ),
        ],
      ),
    );
  }

  Widget _heading(ScoringSheetColumn column) {
    final align = column.centered || column.isWritten
        ? TextAlign.center
        : TextAlign.left;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: column.centered || column.isWritten
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        for (final line in column.title)
          Text(
            line,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: align,
            style: _text(13.33, 15, weight: FontWeight.w700),
          ),
        if (column.hint.isNotEmpty)
          Text(
            column.hint,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            textAlign: align,
            style: _text(12, 14),
          ),
      ],
    );
  }

  /// A ruled cell. Every edge carries a 1 px black rule; [heavy] doubles the
  /// left one where the printed columns end and the writing columns begin.
  Widget _cell(
    double width, {
    required double height,
    required Widget? child,
    bool first = false,
    bool last = false,
    bool heavy = false,
    bool bottom = true,
    Color? fill,
    Alignment alignment = Alignment.center,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  }) => Container(
    width: width,
    height: height,
    alignment: alignment,
    padding: padding,
    decoration: BoxDecoration(
      color: fill,
      border: Border(
        left: BorderSide(color: PaperStyle.ink, width: heavy ? 2 : 1),
        right: last ? const BorderSide(color: PaperStyle.ink) : BorderSide.none,
        bottom: bottom
            ? const BorderSide(color: PaperStyle.ink)
            : BorderSide.none,
      ),
    ),
    child: child,
  );

  Widget _row(ScoringSheetItem item) => switch (item) {
    ScoringSheetRoundRow() => _round(item),
    ScoringSheetGroupRow() => _group(item),
    ScoringSheetPilotRow() => _pilot(item),
  };

  Widget _round(ScoringSheetRoundRow row) => Semantics(
    header: true,
    child: Padding(
      padding: EdgeInsets.only(
        top: row.gapAbove ? ScoringSheetStyle.roundGap : 0,
      ),
      child: Container(
        height: ScoringSheetStyle.roundHeight,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: PaperStyle.ink, width: 3)),
        ),
        child: Text.rich(
          TextSpan(
            text: 'Round ${row.ordinal}',
            children: [
              TextSpan(
                text:
                    '${row.continued ? ' (Continued)' : ''} · Working Time '
                    '$workingTime',
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          style: _text(20, 24, weight: FontWeight.w700),
        ),
      ),
    ),
  );

  Widget _group(ScoringSheetGroupRow row) => Semantics(
    header: true,
    child: Container(
      height: ScoringSheetStyle.groupHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: PaperStyle.ink),
          bottom: BorderSide(color: PaperStyle.ink, width: 2),
        ),
      ),
      child: Text.rich(
        TextSpan(
          text: 'Group ${row.label}',
          children: [
            TextSpan(
              text:
                  '${row.continued ? ' (Continued)' : ''} · ${row.size} '
                  '${row.size == 1 ? 'Pilot' : 'Pilots'}',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
        style: _text(16, 20, weight: FontWeight.w700),
      ),
    ),
  );

  Widget _pilot(ScoringSheetPilotRow row) {
    final split = page.strip.splitIndex;
    return SizedBox(
      height: ScoringSheetStyle.rowHeight,
      child: Row(
        children: [
          for (var i = 0; i < _columns.length; i++)
            _pilotCell(
              row,
              _columns[i],
              first: i == 0,
              last: i == _columns.length - 1,
              heavy: i == split,
            ),
        ],
      ),
    );
  }

  Widget _pilotCell(
    ScoringSheetPilotRow row,
    SizedSheetColumn sized, {
    required bool first,
    required bool last,
    required bool heavy,
  }) {
    final column = sized.column;
    Widget cell(
      Widget? child, {
      Alignment alignment = Alignment.centerLeft,
      Color? fill,
      EdgeInsets? padding,
    }) => _cell(
      sized.width,
      height: ScoringSheetStyle.rowHeight,
      first: first,
      last: last,
      heavy: heavy,
      fill: fill,
      alignment: alignment,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      child: child,
    );

    Widget printed(String text, TextStyle style, {bool centered = false}) =>
        cell(
          // A long value wraps and, if it still does not fit the row, shrinks
          // to fit, so a name is never cut off on paper.
          LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: SizedBox(
                width: box.maxWidth,
                child: Text(
                  text,
                  textAlign: centered ? TextAlign.center : TextAlign.left,
                  style: style,
                ),
              ),
            ),
          ),
          alignment: centered ? Alignment.center : Alignment.centerLeft,
        );

    final pilot = row.pilot.pilot;
    switch (column.id) {
      case ScoringSheetColumnId.lane:
        return printed(
          row.pilot.lane == null ? '' : '${row.pilot.lane}',
          _text(14.67, 15, weight: FontWeight.w700),
          centered: true,
        );
      case ScoringSheetColumnId.name:
        return Semantics(
          header: true,
          child: printed(
            row.marked ? '${row.pilot.name} (R)' : row.pilot.name,
            _text(14.67, 15),
          ),
        );
      case ScoringSheetColumnId.club:
        return printed(pilot.club ?? '', _text(12, 14));
      case ScoringSheetColumnId.team:
        return printed(pilot.team ?? '', _text(12, 14));
      case ScoringSheetColumnId.number:
        return printed(
          pilot.number == null ? '' : '${pilot.number}',
          _text(13.33, 15),
          centered: true,
        );
      case ScoringSheetColumnId.className:
        return printed(pilot.className ?? '', _text(13.33, 15));
      default:
        return _written(row.pilot.score, column, cell);
    }
  }

  /// A cell for writing in; with Pre-fill, the score already entered.
  Widget _written(
    CardScore? score,
    ScoringSheetColumn column,
    Widget Function(
      Widget? child, {
      Alignment alignment,
      Color? fill,
      EdgeInsets? padding,
    })
    cell,
  ) {
    final field = switch (column.id) {
      ScoringSheetColumnId.time => CardField.time,
      ScoringSheetColumnId.landing => CardField.landing,
      ScoringSheetColumnId.height => CardField.height,
      ScoringSheetColumnId.over75 => CardField.over75,
      ScoringSheetColumnId.restart => CardField.restart,
      ScoringSheetColumnId.penalty => CardField.penalty,
      _ => null,
    };
    final filled = score != null && field != null;
    final star = filled && !score.official ? '*' : '';
    if (column.kind == ScoringSheetColumnKind.tick) {
      if (filled) {
        return cell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (score.ticks[field] ?? false)
                _tickBox(
                  const Icon(Icons.check, size: 14, color: PaperStyle.ink),
                )
              else
                Text('–', style: _mono14),
              if (star.isNotEmpty) Text(star, style: _mono14),
            ],
          ),
          fill: PaperStyle.shade,
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
        );
      }
      return cell(
        _tickBox(null),
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
      );
    }
    if (filled) {
      return cell(
        Text(
          '${score.text[field] ?? '–'}$star',
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: _mono14,
        ),
        fill: PaperStyle.shade,
        alignment: Alignment.center,
      );
    }
    return cell(null);
  }

  TextStyle get _mono14 => _text(14, 15, weight: FontWeight.w700).copyWith(
    fontFamily: _mono.first,
    fontFamilyFallback: _mono.skip(1).toList(),
  );

  /// A real box, 5 mm square, to tick.
  Widget _tickBox(Widget? mark) => Container(
    width: ScoringSheetStyle.tickBox,
    height: ScoringSheetStyle.tickBox,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: PaperStyle.paper,
      border: Border.all(color: PaperStyle.ink, width: 1.5),
    ),
    child: mark,
  );
}
