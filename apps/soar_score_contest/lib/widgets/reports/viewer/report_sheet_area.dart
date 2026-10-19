import 'package:flutter/material.dart';

import '../../../services/reports/viewer/page_setup.dart';
import 'paper_style.dart';

/// Zoom steps offered besides "fit width".
const List<double> reportZoomSteps = [.5, .75, 1, 1.25, 1.5];

/// The grey backdrop with the report's pages on it, at a readable zoom and
/// scrolling vertically. Pages wider than the window scroll sideways on screen;
/// the printout is the whole page.
///
/// Outside print preview, a dashed separator labelled with the next page
/// number marks each page break. Those labels exist only on screen.
class ReportSheetArea extends StatefulWidget {
  const ReportSheetArea({
    super.key,
    required this.setup,
    required this.pages,
    required this.zoom,
    required this.preview,
    required this.onFit,
    required this.onPage,
    this.dimmed = false,
  });

  final PageSetup setup;

  /// The finished pages, each exactly [PageSetup] sized.
  final List<Widget> pages;

  /// A fixed zoom; `null` fits the width.
  final double? zoom;
  final bool preview;

  /// Told the zoom that fits the width, so the toolbar can show it.
  final ValueChanged<double> onFit;

  /// Told which page is in view.
  final ValueChanged<int> onPage;

  /// The sheet is being refreshed: it stays and dims slightly.
  final bool dimmed;

  @override
  State<ReportSheetArea> createState() => _ReportSheetAreaState();
}

class _ReportSheetAreaState extends State<ReportSheetArea> {
  final ScrollController _vertical = ScrollController();
  double _lastFit = 0;
  int _lastPage = 0;

  static const double _breakHeight = 32;
  static const double _gap = 24;
  static const double _pad = 24;

  @override
  void initState() {
    super.initState();
    _vertical.addListener(_onScroll);
  }

  @override
  void dispose() {
    _vertical
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  double _scale(double areaWidth) {
    final fit = ((areaWidth - 2 * _pad) / widget.setup.width).clamp(.2, 1.25);
    if (fit != _lastFit) {
      _lastFit = fit;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onFit(fit);
        }
      });
    }
    return widget.zoom ?? fit;
  }

  void _onScroll() {
    if (!_vertical.hasClients || widget.pages.isEmpty) {
      return;
    }
    final k = _lastFit == 0 ? 1.0 : (widget.zoom ?? _lastFit);
    final step =
        widget.setup.height * k + (widget.preview ? _gap : _breakHeight);
    final page = ((_vertical.offset + 80) / step).floor() + 1;
    final clamped = page.clamp(1, widget.pages.length);
    if (clamped != _lastPage) {
      _lastPage = clamped;
      widget.onPage(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: PaperStyle.backdrop(theme.brightness),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final k = _scale(constraints.maxWidth);
          final pageW = widget.setup.width * k;
          final pageH = widget.setup.height * k;
          final contentW = pageW + 2 * _pad;
          final children = <Widget>[];
          for (var i = 0; i < widget.pages.length; i++) {
            if (i > 0) {
              children.add(
                widget.preview
                    ? const SizedBox(height: _gap)
                    : _PageBreak(width: pageW, page: i + 1),
              );
            }
            children.add(
              SizedBox(
                width: pageW,
                height: pageH,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: FittedBox(fit: BoxFit.fill, child: widget.pages[i]),
                ),
              ),
            );
          }
          final column = Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _pad,
              vertical: _pad,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          );
          return Semantics(
            label: 'Report pages',
            container: true,
            child: Opacity(
              opacity: widget.dimmed ? .55 : 1,
              child: Scrollbar(
                controller: _vertical,
                child: SingleChildScrollView(
                  controller: _vertical,
                  child: contentW > constraints.maxWidth
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: column,
                        )
                      : Center(child: column),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A dashed line with the number of the page that starts below it. Screen
/// only: print preview and the printout leave it out.
class _PageBreak extends StatelessWidget {
  const _PageBreak({required this.width, required this.page});

  final double width;
  final int page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: _ReportSheetAreaState._breakHeight,
        child: Row(
          children: [
            Expanded(child: _Dashes(color: color)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_page_break, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Page break · Page $page',
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Expanded(child: _Dashes(color: color)),
          ],
        ),
      ),
    );
  }
}

class _Dashes extends StatelessWidget {
  const _Dashes({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size.fromHeight(1), painter: _DashPainter(color));
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
