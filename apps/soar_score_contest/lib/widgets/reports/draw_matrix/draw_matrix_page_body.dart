import 'package:flutter/material.dart';

import '../../../services/reports/draw_matrix/draw_matrix_layout.dart';
import '../../../services/reports/draw_matrix/draw_matrix_style.dart';
import '../viewer/paper_style.dart';
import 'draw_matrix_table_view.dart';

/// The body of one printed page of the Draw Matrix: one table, or in compact
/// mode two side by side with a black rule between them, each with its own
/// column headings and round and group headers.
class DrawMatrixPageBody extends StatelessWidget {
  const DrawMatrixPageBody({
    super.key,
    required this.layout,
    required this.page,
    required this.number,
    required this.size,
  });

  final DrawMatrixLayout layout;
  final DrawMatrixPage page;

  /// 1-based page number, for the tables' names.
  final int number;

  /// The room the page body has.
  final Size size;

  @override
  Widget build(BuildContext context) {
    final two = layout.style == DrawMatrixStyle.compact;
    return SizedBox(
      width: size.width,
      height: size.height,
      // The layout measured every row; the clip only keeps a font that sets
      // wider than measured from drawing past the page.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < page.tables.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(width: 14),
                  Container(
                    width: 1,
                    height: size.height,
                    color: PaperStyle.ink,
                  ),
                  const SizedBox(width: 13),
                ],
                DrawMatrixTableView(
                  items: page.tables[i],
                  columns: layout.columns,
                  style: layout.style,
                  label: 'Page $number${two ? ', column ${i + 1}' : ''}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
