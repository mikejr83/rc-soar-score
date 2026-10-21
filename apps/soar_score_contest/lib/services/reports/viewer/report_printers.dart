import 'platform_report_printer.dart';
import 'report_print_result.dart';

/// The printer the report viewer uses. An end-to-end test swaps in a fake,
/// because a journey cannot drive a system dialog.
abstract final class ReportPrinters {
  static ReportPrinter current = PlatformReportPrinter();
}
