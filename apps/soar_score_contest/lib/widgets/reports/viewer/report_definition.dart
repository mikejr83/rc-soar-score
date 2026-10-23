import 'package:flutter/widgets.dart';

import '../../../services/reports/report_availability.dart';
import '../../../services/reports/reports_facts.dart';
import '../../../services/reports/result_status.dart';
import '../../../services/reports/viewer/page_setup.dart';
import '../../../services/reports/viewer/report_spec.dart';

/// One titled group of controls in the filter and options panel. The viewer
/// adds its own Page group after the report's.
class ReportControlGroup {
  const ReportControlGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;
}

/// What a report's controls read and change. Changes apply at once.
class ReportControlsContext {
  const ReportControlsContext({
    required this.filters,
    required this.facts,
    required this.check,
    required this.setFilter,
    required this.setFilters,
  });

  /// The filters in force, defaults included.
  final Map<String, String> filters;
  final ReportsFacts facts;

  /// Whether the filters are valid, empty or fine.
  final ReportCheck check;
  final void Function(String key, String value) setFilter;
  final void Function(Map<String, String> changes) setFilters;
}

/// What a report builds its pages from.
class ReportPageContext {
  const ReportPageContext({
    required this.facts,
    required this.filters,
    required this.setup,
    required this.bodySize,
    required this.preview,
    this.data,
  });

  final ReportsFacts facts;

  /// The filters the sheet is built from (the last good ones while the
  /// current ones are invalid).
  final Map<String, String> filters;
  final PageSetup setup;

  /// The room a page body has between the running header and footer.
  final Size bodySize;

  /// Print preview is on: leave out anything that exists only on screen.
  final bool preview;

  /// What the report's `loadData` returned for [filters]; `null` for a report
  /// with no data of its own.
  final Object? data;
}

/// A report ready to draw: the running header, the page bodies and, for a
/// report built from scores, its result status.
class ReportDocument {
  const ReportDocument({
    required this.title,
    required this.subtitle,
    required this.pages,
    this.detail,
    this.notice,
    this.status,
    this.statusReason,
    this.statusAction,
  });

  /// The running header's title, for example "Overall Results - Gator Cup".
  final String title;
  final String subtitle;

  /// A third header line with the contest details.
  final String? detail;

  /// Advice about the sheet for the director, shown on screen above it and
  /// never printed; `null` when there is none.
  final String? notice;

  /// One widget per printed page, each sized to fit [ReportPageContext.bodySize].
  final List<Widget> pages;

  /// The result status; `null` for a report that is not built from scores.
  final ResultStatus? status;

  /// Why the status is not official, in one line, for the screen banner.
  final String? statusReason;
  final ReportAction? statusAction;
}

/// A report the viewer can show: its controls and its pages, on top of the
/// widget-free [ReportSpec].
abstract class ReportDefinition extends ReportSpec {
  const ReportDefinition();

  /// The Filter and Options groups, in panel order.
  List<ReportControlGroup> controls(ReportControlsContext context);

  ReportDocument build(ReportPageContext context);
}

/// A report that reads data of its own, typed as [D]. It answers
/// [loadData] with a `ReportLoad<D>` and builds from a [D], so the one place
/// that checks what the viewer holds is here and not in every report.
///
/// The viewer builds only when the data is loaded, so [buildWith] is never
/// called without it.
abstract class DataReportDefinition<D extends Object> extends ReportDefinition {
  const DataReportDefinition();

  @override
  Future<ReportLoad<D>> loadData(ReportDataRequest request);

  /// The report's pages from its [data].
  ReportDocument buildWith(ReportPageContext context, D data);

  /// What stands in when the viewer has no [D] yet (it does not build then).
  ReportDocument buildWithout(ReportPageContext context) => ReportDocument(
    title: '${kind.title} - ${context.facts.contest.name}',
    subtitle: 'Nothing to show',
    pages: const [SizedBox.shrink()],
  );

  @override
  ReportDocument build(ReportPageContext context) => switch (context.data) {
    final D data => buildWith(context, data),
    _ => buildWithout(context),
  };
}
