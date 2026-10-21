import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'page_setup.dart';
import 'report_pdf_builder.dart';
import 'report_print_result.dart';

/// Builds a PDF whose pages are pictures of the sheet pages, so the printout
/// is exactly what the director saw. The text in it cannot be selected or
/// searched.
class RasterReportPdfBuilder implements ReportPdfBuilder {
  const RasterReportPdfBuilder({this.pixelRatio = 2, this.compress = true});

  /// Image pixels per logical pixel: 2 gives about 192 dpi.
  final double pixelRatio;

  /// Compress the PDF's structure; a test turns it off to read the pages.
  final bool compress;

  /// A sheet page is laid out at 96 to the inch; a PDF point is 1/72 inch.
  static const double _pointsPerPixel = 0.75;

  @override
  Future<Uint8List> build(ReportPrintJob job) async {
    final setup = job.setup;
    if (job.pages.isEmpty) {
      throw ArgumentError('A print job needs pages.');
    }
    final format = pdfPageFormat(setup);
    final document = pw.Document(title: job.title, compress: compress);
    // Each page is painted and handed to the document in turn, but the
    // document keeps every page's pixels until `save`, so memory grows with
    // the page count (about 9 MB per A4 page at the default ratio). The
    // pixels go in raw, which spares an encode and a decode of each page.
    for (final page in job.pages) {
      final image = await _capture(page, setup.size);
      document.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
        ),
      );
    }
    return document.save();
  }

  /// The PDF page size for [setup].
  static PdfPageFormat pdfPageFormat(PageSetup setup) => PdfPageFormat(
    setup.width * _pointsPerPixel,
    setup.height * _pointsPerPixel,
  );

  Future<pw.RawImage> _capture(Widget page, Size size) async {
    final image = await _paint(page, size);
    try {
      final data = await image.toByteData();
      return pw.RawImage(
        bytes: data!.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
    }
  }

  /// Lays out and paints [page] in a render tree of its own, never shown, and
  /// reads the picture back.
  Future<ui.Image> _paint(Widget page, Size size) async {
    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        devicePixelRatio: 1,
      ),
      child: RenderPositionedBox(alignment: Alignment.topLeft, child: boundary),
    );
    final pipeline = PipelineOwner()..rootNode = renderView;
    renderView.prepareInitialFrame();
    final focus = FocusManager();
    final build = BuildOwner(focusManager: focus);
    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
            ],
            child: Material(
              type: MaterialType.transparency,
              child: SizedBox.fromSize(size: size, child: page),
            ),
          ),
        ),
      ),
    ).attachToRenderTree(build);
    try {
      build.buildScope(root);
      build.finalizeTree();
      pipeline
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();
      return await boundary.toImage(pixelRatio: pixelRatio);
    } finally {
      // Unmount the page so nothing keeps listening after the capture.
      RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
          .attachToRenderTree(build, root);
      build.finalizeTree();
      focus.dispose();
      pipeline.rootNode = null;
    }
  }
}
