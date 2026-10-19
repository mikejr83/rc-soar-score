import 'package:flutter/material.dart';

import '../../services/reports/report_kind.dart';

/// A small paper-like drawing that stands for a report at a glance. It is
/// decorative: the card's title and brief are the accessible name, so it is
/// excluded from semantics.
class ReportThumbnail extends StatelessWidget {
  const ReportThumbnail({
    super.key,
    required this.kind,
    required this.size,
    this.faded = false,
  });

  final ReportKind kind;
  final double size;

  /// An unavailable report's thumbnail is dimmed.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Opacity(
        opacity: faded ? 0.45 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(painter: _ThumbnailPainter(kind, scheme)),
          ),
        ),
      ),
    );
  }
}

/// Draws on a 120 by 120 grid scaled to the box, in the theme's tonal roles
/// so it works in light and dark.
class _ThumbnailPainter extends CustomPainter {
  _ThumbnailPainter(this.kind, this.scheme);

  final ReportKind kind;
  final ColorScheme scheme;

  late Canvas _canvas;

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, [double width = 1]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  void _rect(
    double x,
    double y,
    double w,
    double h,
    Paint paint, {
    double radius = 0,
  }) => _canvas.drawRRect(
    RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(radius)),
    paint,
  );

  /// The page: a paper-coloured rectangle with a hairline.
  void _page(double x, double y, double w, double h, double radius) {
    final page = scheme.surfaceContainerLowest;
    _rect(x, y, w, h, _fill(page), radius: radius);
    _rect(x, y, w, h, _stroke(scheme.outlineVariant), radius: radius);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _canvas = canvas;
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);
    switch (kind) {
      case ReportKind.standings:
        _standings();
      case ReportKind.matrix:
        _matrix();
      case ReportKind.sheet:
        _sheet();
      case ReportKind.cards:
        _cards();
    }
    canvas.restore();
  }

  void _standings() {
    final primary = _fill(scheme.primary);
    final cell = _fill(scheme.outlineVariant);
    _page(8, 24, 104, 74, 4);
    _rect(16, 32, 40, 6, primary, radius: 2);
    _rect(16, 43, 88, 1.5, primary);
    // The highlighted (dropped) round cell.
    _rect(80, 47, 14, 10, _fill(scheme.tertiaryContainer), radius: 2);
    _rect(80, 47, 14, 10, _stroke(scheme.tertiary), radius: 2);
    const rows = [49.0, 60.0, 71.0, 82.0];
    const names = [28.0, 24.0, 30.0, 22.0];
    for (var i = 0; i < rows.length; i++) {
      final y = rows[i];
      _rect(16, y, 6, 5, primary);
      _rect(26, y, names[i], 5, cell);
      _rect(58, y, 9, 5, cell);
      _rect(70, y, 7, 5, cell);
      _rect(83, y, 8, 5, i == 0 ? _fill(scheme.onTertiaryContainer) : cell);
      _rect(96, y, 8, 5, primary);
    }
  }

  void _matrix() {
    final block = _fill(scheme.primaryContainer);
    final edge = _stroke(scheme.primary, .8);
    _page(8, 24, 104, 74, 4);
    _rect(16, 32, 36, 6, _fill(scheme.primary), radius: 2);
    for (final y in [44.0, 58.0, 72.0]) {
      for (final x in [30.0, 56.0, 82.0]) {
        _rect(x, y, 22, 10, block, radius: 2);
        _rect(x, y, 22, 10, edge, radius: 2);
      }
      _rect(16, y + 2, 9, 6, _fill(scheme.primary), radius: 1);
    }
    for (final x in [30.0, 56.0, 82.0]) {
      _rect(x, 86, 22, 6, _fill(scheme.tertiaryContainer), radius: 2);
      _rect(x, 86, 22, 6, _stroke(scheme.tertiary, .8), radius: 2);
    }
  }

  void _sheet() {
    _page(26, 8, 68, 104, 4);
    _rect(33, 15, 30, 6, _fill(scheme.primary), radius: 2);
    _rect(33, 27, 54, 7, _fill(scheme.primaryContainer));
    final grid = Path()..addRect(const Rect.fromLTRB(33, 27, 87, 104));
    for (var y = 34.0; y <= 97; y += 7) {
      grid
        ..moveTo(33, y)
        ..lineTo(87, y);
    }
    for (final x in [43.0, 60.0, 72.0]) {
      grid
        ..moveTo(x, 27)
        ..lineTo(x, 104);
    }
    _canvas.drawPath(grid, _stroke(scheme.primary, .8));
  }

  void _cards() {
    final primary = _fill(scheme.primary);
    final line = _fill(scheme.outlineVariant);
    _page(10, 10, 100, 100, 4);
    final cut = Path()
      ..moveTo(60, 14)
      ..lineTo(60, 106)
      ..moveTo(14, 60)
      ..lineTo(106, 60);
    _dashed(cut, _stroke(scheme.outline));
    for (final (x, y) in [
      (18.0, 18.0),
      (70.0, 18.0),
      (18.0, 64.0),
      (70.0, 64.0),
    ]) {
      _rect(x, y + 2, x == 18 ? 20 : 18, 4, primary);
      for (final dy in [18.0, 24.0, 30.0]) {
        _rect(x, y + dy, 34, 3, line);
      }
    }
    // The QR squares.
    final modules = _fill(scheme.surfaceContainerLowest);
    for (final (x, y) in [
      (42.0, 18.0),
      (94.0, 18.0),
      (42.0, 64.0),
      (94.0, 64.0),
    ]) {
      _rect(x, y, 12, 12, primary, radius: 1);
      _rect(x + 2.5, y + 2.5, 3, 3, modules);
      _rect(x + 7, y + 7, 3, 3, modules);
    }
  }

  void _dashed(Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 5) {
        _canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ThumbnailPainter old) =>
      old.kind != kind || old.scheme != scheme;
}
