import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import 'raster_report_pdf_builder.dart';
import 'report_pdf_builder.dart';
import 'report_print_result.dart';

/// Prints through the machine's own print dialog and saves PDFs where the
/// director chooses, on web and Windows.
class PlatformReportPrinter implements ReportPrinter {
  const PlatformReportPrinter({
    this.builder = const RasterReportPdfBuilder(),
    this.printDialog = _layoutPdf,
    this.saveFile = _saveFile,
  });

  final ReportPdfBuilder builder;

  /// Opens the print dialog with the PDF; `true` when printed, `false` when
  /// the director cancelled. A test swaps in its own.
  final PrintDialog printDialog;

  /// Saves the PDF; `null` when the director cancelled. A test swaps in its
  /// own.
  final SavePdfFile saveFile;

  @override
  ReportPrintCapabilities get capabilities => const ReportPrintCapabilities();

  @override
  Future<ReportPrintResult> print(ReportPrintJob job) async {
    try {
      final bytes = await builder.build(job);
      final printed = await printDialog(job, bytes);
      // A browser reports nothing once its dialog closes.
      if (kIsWeb) {
        return ReportPrintResult.unknown;
      }
      return printed ? ReportPrintResult.sent : ReportPrintResult.cancelled;
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'report printing',
        ),
      );
      return ReportPrintResult.failed;
    }
  }

  @override
  Future<ReportPrintResult> savePdf(ReportPrintJob job) async {
    try {
      final bytes = await builder.build(job);
      final saved = await saveFile(fileNameFor(job.title), bytes);
      return saved ? ReportPrintResult.sent : ReportPrintResult.cancelled;
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'report printing',
        ),
      );
      return ReportPrintResult.failed;
    }
  }

  /// `{Report} – {Contest}.pdf` with the characters a file name cannot hold
  /// replaced.
  static String fileNameFor(String title) =>
      '${title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '-').trim()}.pdf';
}

typedef PrintDialog = Future<bool> Function(ReportPrintJob job, Uint8List pdf);

typedef SavePdfFile = Future<bool> Function(String fileName, Uint8List pdf);

Future<bool> _layoutPdf(ReportPrintJob job, Uint8List pdf) =>
    Printing.layoutPdf(
      name: job.title,
      format: RasterReportPdfBuilder.pdfPageFormat(job.setup!),
      onLayout: (_) async => pdf,
    );

/// The browser downloads the file; a desktop build asks where to put it.
Future<bool> _saveFile(String fileName, Uint8List pdf) async {
  if (kIsWeb) {
    return Printing.sharePdf(bytes: pdf, filename: fileName);
  }
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: ['pdf']),
    ],
  );
  if (location == null) {
    return false;
  }
  await File(location.path).writeAsBytes(pdf);
  return true;
}
