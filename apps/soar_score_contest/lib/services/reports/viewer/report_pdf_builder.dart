import 'dart:typed_data';

import 'report_print_result.dart';

/// Turns a finished sheet into the bytes of a PDF.
///
/// The printer never learns how the bytes were made. [RasterReportPdfBuilder]
/// puts each sheet page in the PDF as an image; a builder that draws a report
/// as text can replace it one report at a time if directors need selectable,
/// searchable text.
abstract class ReportPdfBuilder {
  Future<Uint8List> build(ReportPrintJob job);
}
