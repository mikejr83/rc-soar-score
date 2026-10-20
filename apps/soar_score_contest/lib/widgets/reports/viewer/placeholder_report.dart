import 'package:flutter/material.dart';

import '../../../services/reports/report_kind.dart';
import '../../../services/reports/viewer/page_setup.dart';
import 'paper_style.dart';
import '../standings/standings_report.dart';
import 'report_definition.dart';

/// Stands in for a report whose content is not built yet. It has no filters
/// and one page that says so, so the viewer frame (page setup, zoom, print
/// preview, footer, the states) can be used and checked end to end. Each real
/// report replaces it with its own [ReportDefinition].
class PlaceholderReport extends ReportDefinition {
  const PlaceholderReport(this.kind);

  @override
  final ReportKind kind;

  /// The standings are laid out in landscape; the rest start in portrait until
  /// their own briefs say otherwise.
  @override
  PageOrientation get defaultOrientation => kind == ReportKind.standings
      ? PageOrientation.landscape
      : PageOrientation.portrait;

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) => const [
    ReportControlGroup(
      title: 'Filter',
      children: [Text('This report has no filters yet.')],
    ),
  ];

  @override
  ReportDocument build(ReportPageContext context) {
    final facts = context.facts;
    return ReportDocument(
      title: '${kind.title} - ${facts.contest.name}',
      subtitle: 'Content not built yet',
      detail: facts.hasMatrix
          ? '${facts.roundCount} rounds drawn'
          : 'No matrix drawn',
      pages: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: PaperStyle.ink),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kind.title} isn’t built yet',
                    style: PaperStyle.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This page stands in for the report so the viewer can be '
                    'used. ${kind.brief}',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The definition for [kind]. A report is a placeholder until its content is
/// built.
ReportDefinition reportDefinitionFor(ReportKind kind) => switch (kind) {
  ReportKind.standings => const StandingsReport(),
  _ => PlaceholderReport(kind),
};
