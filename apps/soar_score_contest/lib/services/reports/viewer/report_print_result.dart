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

  /// The name of the file the last successful [savePdf] wrote, which the
  /// director may have changed in the save dialog; `null` when unknown.
  String? get lastSavedName;

  Future<ReportPrintResult> print(ReportPrintJob job);

  Future<ReportPrintResult> savePdf(ReportPrintJob job);
}

/// What is printed: the title (also the base of a PDF's file name), the
/// finished sheet pages and the setup the dialog is told about.
class ReportPrintJob {
  const ReportPrintJob({
    required this.title,
    required this.setup,
    required this.pages,
  });

  final String title;

  /// The paper and orientation the [pages] are laid out for.
  final PageSetup setup;

  /// The finished sheet pages, each exactly [setup] sized.
  final List<Widget> pages;

  int get pageCount => pages.length;
  String get paperLabel => setup.paper.label;
  String get orientationLabel => setup.orientation.label;
}

/// The printer until printing is built: every request answers [notWired].
class NotWiredReportPrinter implements ReportPrinter {
  const NotWiredReportPrinter();

  @override
  ReportPrintCapabilities get capabilities => const ReportPrintCapabilities();

  @override
  String? get lastSavedName => null;

  @override
  Future<ReportPrintResult> print(ReportPrintJob job) async =>
      ReportPrintResult.notWired;

  @override
  Future<ReportPrintResult> savePdf(ReportPrintJob job) async =>
      ReportPrintResult.notWired;
}
