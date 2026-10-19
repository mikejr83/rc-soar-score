import '../report_kind.dart';
import '../reports_facts.dart';
import 'page_setup.dart';

/// What the viewer asks of a filter set: it is fine, it is invalid (the sheet
/// stays on the last good result), or it selects nothing.
sealed class ReportCheck {
  const ReportCheck();

  static const ReportCheck ok = _Ok();
}

final class _Ok extends ReportCheck {
  const _Ok();
}

/// The filters contradict each other, for example a lower round above the
/// upper one. [message] sits inline by the control.
final class ReportInvalid extends ReportCheck {
  const ReportInvalid(this.message);

  final String message;
}

/// The filters are valid but nothing is left to show.
final class ReportEmpty extends ReportCheck {
  const ReportEmpty({required this.title, required this.body});

  final String title;
  final String body;
}

/// The parts of a report the viewer's logic needs, free of widgets: what it is
/// called, how it starts and when its filters are wrong. A report adds its
/// controls and pages in `ReportDefinition`.
abstract class ReportSpec {
  const ReportSpec();

  ReportKind get kind;

  /// The orientation the report starts with; the director can change it.
  PageOrientation get defaultOrientation => PageOrientation.landscape;

  /// Whether the report is built from scores and so carries a result status.
  bool get dependsOnScores => false;

  /// The filters that apply when the URL names none.
  Map<String, String> defaultFilters(ReportsFacts facts) => const {};

  /// Judges [filters] (defaults already applied).
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) =>
      ReportCheck.ok;

  /// The filters in a few words, for the collapsed bar ("Rounds 1–6").
  String filterSummary(Map<String, String> filters, ReportsFacts facts) => '';
}
