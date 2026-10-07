import 'package:flutter/material.dart';

/// A child of a [SpanGrid] that takes [span] of its columns.
class SpanGridItem {
  const SpanGridItem({required this.span, required this.child});

  final int span;
  final Widget child;
}

/// Lays out fields on a fixed column grid (six columns by default), wrapping
/// to a new row when a field does not fit, so a form can reflow between
/// wide and narrow windows by changing spans only.
class SpanGrid extends StatelessWidget {
  const SpanGrid({
    super.key,
    required this.items,
    this.columns = 6,
    this.columnGap = 16,
    this.rowGap = 20,
  });

  final List<SpanGridItem> items;
  final int columns;
  final double columnGap;
  final double rowGap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final column =
          (constraints.maxWidth - columnGap * (columns - 1)) / columns;
      return Wrap(
        spacing: columnGap,
        runSpacing: rowGap,
        children: [
          for (final item in items)
            SizedBox(
              width: column * item.span + columnGap * (item.span - 1),
              child: item.child,
            ),
        ],
      );
    },
  );
}
