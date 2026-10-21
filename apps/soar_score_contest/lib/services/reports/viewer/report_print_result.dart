import 'package:flutter/widgets.dart';

import 'page_setup.dart';

/// What happened when the director asked to print or save a report.
enum ReportPrintResult {
  /// Sent to the printer or saved as a PDF.
  sent,

  /// The director closed the system dialog.
  cancelled,

  /// The platform reported an error. Nothing is lost; retry is offered.
  failed,

  /// The platform gave no answer (a browser reports nothing after its dialog
  /// closes), so the viewer stays quiet.
  unknown,

  /// Printing is not wired up in this build yet.
  notWired,
}

/// What the platform can do with a finished sheet.
class ReportPrintCapabilities {
  const ReportPrintCapabilities({this.canPrint = true, this.canSavePdf = true});

  final bool canPrint;
  final bool canSavePdf;
}

/// Opens the platform's own print dialog for a sheet. The viewer sets paper
/// and orientation, then hands over; the real dialog belongs to the platform.
///
/// [PlatformReportPrinter] is the real one; [NotWiredReportPrinter] stands in
/// where a build has no printing.
abstract class ReportPrinter {
  ReportPrintCapabilities get capabilities;

  Future<ReportPrintResult> print(ReportPrintJob job);

  Future<ReportPrintResult> savePdf(ReportPrintJob job);
}

/// What is printed: the title (also the PDF's file name), the finished sheet
/// pages and the setup the dialog is told about.
class ReportPrintJob {
  const ReportPrintJob({
    required this.title,
    required this.pageCount,
    required this.paperLabel,
    required this.orientationLabel,
    this.setup,
    this.pages = const [],
  });

  final String title;

  /// The paper and orientation the [pages] are laid out for.
  final PageSetup? setup;

  /// The finished sheet pages, each exactly [setup] sized. Empty for a printer
  /// that only records the job.
  final List<Widget> pages;
  final int pageCount;
  final String paperLabel;
  final String orientationLabel;
}

/// The printer until printing is built: every request answers [notWired].
class NotWiredReportPrinter implements ReportPrinter {
  const NotWiredReportPrinter();

  @override
  ReportPrintCapabilities get capabilities => const ReportPrintCapabilities();

  @override
  Future<ReportPrintResult> print(ReportPrintJob job) async =>
      ReportPrintResult.notWired;

  @override
  Future<ReportPrintResult> savePdf(ReportPrintJob job) async =>
      ReportPrintResult.notWired;
}
