import 'package:flutter/foundation.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

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

/// What a report's `loadData` answers: the data its sheet is built from, that
/// the server has none yet, or that these filters need none.
///
/// A report with data of its own extends `DataReportDefinition<D>` and answers
/// with a `ReportLoad<D>`, so it never casts or null-checks what the viewer
/// hands back.
sealed class ReportLoad<D extends Object> {
  const ReportLoad();
}

/// The data for the filters asked about.
final class ReportLoaded<D extends Object> extends ReportLoad<D> {
  const ReportLoaded(this.data);

  final D data;
}

/// The filters select nothing to read, for example an empty round range. The
/// report's `check` explains why; there is no sheet.
final class ReportNothingToLoad extends ReportLoad<Never> {
  const ReportNothingToLoad();
}

/// What a report's `loadData` returns when the server has nothing to build the
/// sheet from yet. The viewer shows [title] and [body] in place of the sheet,
/// with a link to [actionLabel]'s page, instead of an error.
final class ReportNoData extends ReportLoad<Never> {
  const ReportNoData({
    required this.title,
    required this.body,
    required this.actionLabel,
    this.round,
  });

  final String title;
  final String body;
  final String actionLabel;

  /// The round to open Scoring at.
  final int? round;
}

/// What a report needs to read the data behind a set of filters.
class ReportDataRequest {
  const ReportDataRequest({
    required this.client,
    required this.contestId,
    required this.facts,
    required this.filters,
  });

  final ApiClient client;
  final Id contestId;
  final ReportsFacts facts;

  /// The filters the data is for, defaults applied.
  final Map<String, String> filters;
}

/// The parts of a report the viewer's logic needs, free of widgets: what it is
/// called, how it starts and when its filters are wrong. A report adds its
/// controls and pages in `ReportDefinition`.
abstract class ReportSpec {
  const ReportSpec();

  ReportKind get kind;

  /// The orientation the report starts with; the director can change it.
  PageOrientation get defaultOrientation => PageOrientation.landscape;

  /// The page setup offers no orientation: the report prints one way only.
  bool get fixedOrientation => false;

  /// Whether the frame's running header and footer surround each page. A
  /// report cut apart after printing draws its own on every card.
  bool get hasRunningFrame => true;

  /// Tells the viewer when something inside [data] changes by itself, for
  /// example an invitation being sent, so the sheet and banners redraw.
  Listenable? changesOf(Object? data) => null;

  /// Whether the report is built from scores and so carries a result status.
  bool get dependsOnScores => false;

  /// The filters that apply when the URL names none.
  Map<String, String> defaultFilters(ReportsFacts facts) => const {};

  /// Judges [filters] (defaults already applied).
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) =>
      ReportCheck.ok;

  /// Names the data [filters] need, or `null` when the report builds from the
  /// viewer's facts alone. The viewer reads the data again only when the key
  /// changes, so toggling a column that needs no new data redraws at once.
  String? dataKey(Map<String, String> filters, ReportsFacts facts) => null;

  /// Reads the data [dataKey] names. Failures are thrown; the viewer keeps the
  /// last good sheet and offers a retry.
  Future<ReportLoad<Object>> loadData(ReportDataRequest request) async =>
      const ReportNothingToLoad();

  /// The filters in a few words, for the collapsed bar ("Rounds 1–6").
  String filterSummary(Map<String, String> filters, ReportsFacts facts) => '';
}
