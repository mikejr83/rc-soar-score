import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';

import 'raster_report_pdf_builder.dart';
import 'report_pdf_builder.dart';
import 'report_print_result.dart';

/// Prints through the machine's own print dialog and saves PDFs where the
/// director chooses, on web and Windows.
class PlatformReportPrinter implements ReportPrinter {
  PlatformReportPrinter({
    this.builder = const RasterReportPdfBuilder(),
    this.printDialog = _layoutPdf,
    this.saveFile = _saveFile,
  });

  final ReportPdfBuilder builder;

  /// Opens the print dialog with the PDF; `true` when printed, `false` when
  /// the director cancelled. A test swaps in its own.
  final PrintDialog printDialog;

  /// Saves the PDF and answers the name of the file written, or `null` when
  /// the director cancelled. A test swaps in its own.
  final SavePdfFile saveFile;

  String? _lastSavedName;

  @override
  ReportPrintCapabilities get capabilities => const ReportPrintCapabilities();

  @override
  String? get lastSavedName => _lastSavedName;

  @override
  Future<ReportPrintResult> print(ReportPrintJob job) => _guard(() async {
    final bytes = await builder.build(job);
    final printed = await printDialog(job, bytes);
    // A browser reports nothing once its dialog closes.
    if (kIsWeb) {
      return ReportPrintResult.unknown;
    }
    return printed ? ReportPrintResult.sent : ReportPrintResult.cancelled;
  });

  @override
  Future<ReportPrintResult> savePdf(ReportPrintJob job) => _guard(() async {
    final bytes = await builder.build(job);
    final name = await saveFile(fileNameFor(job.title), bytes);
    if (name == null) {
      return ReportPrintResult.cancelled;
    }
    _lastSavedName = name;
    return ReportPrintResult.sent;
  });

  /// Any error becomes [ReportPrintResult.failed], reported to the framework.
  Future<ReportPrintResult> _guard(
    Future<ReportPrintResult> Function() action,
  ) async {
    try {
      return await action();
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

  static final _illegal = RegExp(r'[\\/:*?"<>|\x00-\x1f]');
  static final _reserved = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
    caseSensitive: false,
  );
  static const _maxBaseLength = 120;

  /// `{Report} – {Contest}.pdf` made safe for a file system: characters it
  /// refuses are replaced, Windows' reserved names, trailing dots and spaces
  /// and an empty or very long title are handled.
  static String fileNameFor(String title) {
    var base = title.replaceAll(_illegal, '-').trim();
    if (base.length > _maxBaseLength) {
      base = base.substring(0, _maxBaseLength);
    }
    base = base.replaceAll(RegExp(r'[. ]+$'), '');
    if (base.isEmpty) {
      base = 'Report';
    } else if (_reserved.hasMatch(base)) {
      base = '$base-';
    }
    return '$base.pdf';
  }
}

typedef PrintDialog = Future<bool> Function(ReportPrintJob job, Uint8List pdf);

typedef SavePdfFile = Future<String?> Function(String fileName, Uint8List pdf);

Future<bool> _layoutPdf(ReportPrintJob job, Uint8List pdf) =>
    Printing.layoutPdf(
      name: job.title,
      format: RasterReportPdfBuilder.pdfPageFormat(job.setup),
      onLayout: (_) async => pdf,
    );

/// The browser downloads the file; a desktop build asks where to put it.
Future<String?> _saveFile(String fileName, Uint8List pdf) async {
  if (kIsWeb) {
    final saved = await Printing.sharePdf(bytes: pdf, filename: fileName);
    return saved ? fileName : null;
  }
  final location = await getSaveLocation(
    suggestedName: fileName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PDF', extensions: ['pdf']),
    ],
  );
  if (location == null) {
    return null;
  }
  await File(location.path).writeAsBytes(pdf);
  return p.basename(location.path);
}
