import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../../services/reports/result_status.dart';
import '../../../services/reports/viewer/page_setup.dart';
import 'paper_style.dart';

/// The room on a paper page: margins, and the running header and footer every
/// page repeats.
abstract final class SheetLayout {
  static const double marginX = 16;
  static const double marginTop = 24;
  static const double marginBottom = 14;
  static const double headerHeight = 72;
  static const double footerHeight = 40;

  /// What a report's page body can use when the page has no running header or
  /// footer: the page inside its margins.
  static Size bareBodySize(PageSetup setup, EdgeInsets margins) =>
      Size(setup.width - margins.horizontal, setup.height - margins.vertical);

  /// What a report's page body can use.
  static Size bodySize(PageSetup setup, {double extraSide = 0}) => Size(
    setup.width - 2 * (marginX + extraSide),
    setup.height - marginTop - headerHeight - footerHeight - marginBottom,
  );
}

/// One printed page without the running header and footer, for a report that
/// draws its own on every card. It keeps the page margins and the paper style.
class ReportBarePage extends StatelessWidget {
  const ReportBarePage({
    super.key,
    required this.setup,
    required this.reportName,
    required this.pageNumber,
    required this.pageCount,
    required this.body,
    required this.margins,
  });

  final PageSetup setup;
  final String reportName;
  final int pageNumber;
  final int pageCount;
  final Widget body;

  /// The blank border the printer cannot reach, as the report asks for it.
  final EdgeInsets margins;

  @override
  Widget build(BuildContext context) => Theme(
    data: PaperStyle.theme(),
    child: DefaultTextStyle(
      style: PaperStyle.body,
      child: Semantics(
        container: true,
        label: '$reportName, page $pageNumber of $pageCount',
        child: Container(
          width: setup.width,
          height: setup.height,
          color: PaperStyle.paper,
          padding: margins,
          child: ClipRect(child: body),
        ),
      ),
    ),
  );
}

/// One printed page: the running header with contest identity and, when the
/// result is not official, the stamp; the report's [body]; and the running
/// footer with the report name, page number, generated time and revisions.
///
/// Everything here prints. The page is black on white and ignores the theme.
class ReportSheetPage extends StatelessWidget {
  const ReportSheetPage({
    super.key,
    required this.setup,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.reportName,
    required this.pageNumber,
    required this.pageCount,
    required this.generated,
    required this.body,
    this.status,
    this.extraSideMargin = 0,
  });

  final PageSetup setup;

  /// Blank space added down each side, header and footer included, as the
  /// report asks for it.
  final double extraSideMargin;
  final String title;
  final String subtitle;
  final String? detail;
  final String reportName;
  final int pageNumber;
  final int pageCount;

  /// "Generated 18 Oct 2026, 14:32 · Matrix rev 3 · Config rev 7".
  final String generated;
  final Widget body;

  /// The result status of a report built from scores; `null` otherwise.
  final ResultStatus? status;

  @override
  Widget build(BuildContext context) {
    final stamp = switch (status) {
      ResultStatus.preliminary => 'PRELIMINARY',
      _ => null,
    };
    return Theme(
      data: PaperStyle.theme(),
      child: DefaultTextStyle(
        style: PaperStyle.body,
        child: Semantics(
          container: true,
          label: '$reportName, page $pageNumber of $pageCount',
          child: Container(
            width: setup.width,
            height: setup.height,
            color: PaperStyle.paper,
            padding: EdgeInsets.fromLTRB(
              SheetLayout.marginX + extraSideMargin,
              SheetLayout.marginTop,
              SheetLayout.marginX + extraSideMargin,
              SheetLayout.marginBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: SheetLayout.headerHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PaperStyle.body.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PaperStyle.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (detail != null)
                              Text(
                                detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PaperStyle.body.copyWith(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      if (stamp != null)
                        Padding(
                          padding: EdgeInsetsGeometry.only(right: 16),
                          child: ResultStamp(text: stamp),
                        ),
                      const BrandLogo(
                        variant: BrandLogoVariant.lockup,
                        height: 32,
                      ),
                    ],
                  ),
                ),
                Expanded(child: ClipRect(child: body)),
                _Footer(
                  reportName: reportName,
                  pageNumber: pageNumber,
                  pageCount: pageCount,
                  generated: generated,
                  statusWord: switch (status) {
                    ResultStatus.official => 'OFFICIAL',
                    ResultStatus.preliminary => 'PRELIMINARY',
                    _ => null,
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.reportName,
    required this.pageNumber,
    required this.pageCount,
    required this.generated,
    required this.statusWord,
  });

  final String reportName;
  final int pageNumber;
  final int pageCount;
  final String generated;
  final String? statusWord;

  @override
  Widget build(BuildContext context) {
    final small = PaperStyle.body.copyWith(fontSize: 10);
    return SizedBox(
      height: SheetLayout.footerHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: PaperStyle.ink)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The two sides share the room equally, so the generated time
              // sits in the middle of the page whatever the sides say.
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: reportName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' · Page $pageNumber of $pageCount'),
                      ],
                    ),
                    style: small,
                  ),
                ),
              ),
              Text(generated, textAlign: TextAlign.center, style: small),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: statusWord == null
                      ? const SizedBox.shrink()
                      : Text(
                          statusWord!,
                          style: small.copyWith(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bordered text stamp on a hatched ground, so it reads in black and white:
/// shape and word, never colour.
class ResultStamp extends StatelessWidget {
  const ResultStamp({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$text result',
    child: ExcludeSemantics(
      child: CustomPaint(
        painter: _HatchPainter(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: PaperStyle.ink, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: PaperStyle.paper,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  text,
                  style: PaperStyle.body.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                color: PaperStyle.paper,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Not final · scores incomplete',
                  style: PaperStyle.body.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HatchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..strokeWidth = 1.5;
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}
