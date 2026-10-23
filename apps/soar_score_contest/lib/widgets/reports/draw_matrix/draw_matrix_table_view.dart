import 'package:flutter/material.dart';

import '../../../services/reports/draw_matrix/draw_matrix_columns.dart';
import '../../../services/reports/draw_matrix/draw_matrix_layout.dart';
import '../../../services/reports/draw_matrix/draw_matrix_style.dart';
import '../viewer/paper_style.dart';

/// One table of the Draw Matrix: the column headings, then the round, group and
/// pilot rows [items] holds. Black and white: nothing depends on the shade or
/// on colour, the label text names each level.
///
/// The rows are real table semantics: round and group rows are headers, the
/// pilot name is the row header.
class DrawMatrixTableView extends StatelessWidget {
  const DrawMatrixTableView({
    super.key,
    required this.items,
    required this.columns,
    required this.style,
    required this.label,
  });

  final List<DrawMatrixItem> items;
  final List<DrawMatrixColumn> columns;
  final DrawMatrixStyle style;

  /// Names the table for a screen reader ("Page 2").
  final String label;

  TextStyle _text(double size, double line, {FontWeight? weight}) =>
      PaperStyle.body.copyWith(
        fontSize: size,
        height: line / size,
        fontWeight: weight,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  Widget build(BuildContext context) {
    final width = columns.fold(0.0, (sum, column) => sum + column.width);
    return Semantics(
      container: true,
      label: label,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_headings(), for (final item in items) _row(item)],
        ),
      ),
    );
  }

  Widget _headings() {
    final head = _text(style.headFont, style.headLine, weight: FontWeight.w700);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PaperStyle.ink, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final column in columns)
            SizedBox(
              width: column.width,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: style.headPadY,
                  horizontal: style.padX,
                ),
                child: Text(
                  column.title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  textAlign: column.alignRight
                      ? TextAlign.right
                      : TextAlign.left,
                  style: head,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(DrawMatrixItem item) => switch (item) {
    DrawMatrixRoundRow() => _round(item),
    DrawMatrixGroupRow() => _group(item),
    DrawMatrixPilotRow() => _pilot(item),
  };

  Widget _round(DrawMatrixRoundRow row) {
    final bold = _text(
      style.roundFont,
      style.roundLine,
      weight: FontWeight.w700,
    );
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.only(top: row.gapAbove ? style.roundGap : 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: PaperStyle.ink, width: style.roundRule),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: style.roundPadY,
              horizontal: style.padX,
            ),
            child: Text.rich(
              TextSpan(
                text: 'Round ${row.ordinal}',
                children: [
                  if (row.continued)
                    const TextSpan(
                      text: ' (continued)',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                ],
              ),
              style: bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(DrawMatrixGroupRow row) {
    final bold = _text(
      style.groupFont,
      style.groupLine,
      weight: FontWeight.w700,
    );
    return Semantics(
      header: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: PaperStyle.dropShade,
          border: Border.symmetric(
            horizontal: BorderSide(color: PaperStyle.ink),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: style.groupPadY,
            horizontal: style.padX,
          ),
          child: Text.rich(
            TextSpan(
              text: 'Group ${row.label}',
              children: [
                TextSpan(
                  text:
                      '${row.continued ? ' (continued)' : ''} · '
                      '${row.size} ${row.size == 1 ? 'pilot' : 'pilots'}',
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
            style: bold,
          ),
        ),
      ),
    );
  }

  Widget _pilot(DrawMatrixPilotRow row) {
    final plain = _text(style.fontSize, style.lineHeight);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PaperStyle.rule)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in columns)
            SizedBox(
              width: column.width,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: style.padY,
                  horizontal: style.padX,
                ),
                child: Text(
                  column.textOf(row.pilot),
                  textAlign: column.alignRight
                      ? TextAlign.right
                      : TextAlign.left,
                  style: column.id == DrawMatrixColumnId.lane
                      ? plain.copyWith(fontWeight: FontWeight.w700)
                      : plain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
