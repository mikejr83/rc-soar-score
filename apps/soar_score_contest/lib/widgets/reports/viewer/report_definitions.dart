import '../../../services/reports/report_kind.dart';
import '../draw_matrix/draw_matrix_report.dart';
import '../pilot_cards/pilot_cards_report.dart';
import '../scoring_sheet/scoring_sheet_report.dart';
import '../standings/standings_report.dart';
import 'report_definition.dart';

/// The definition for [kind].
ReportDefinition reportDefinitionFor(ReportKind kind) => switch (kind) {
  ReportKind.standings => const StandingsReport(),
  ReportKind.matrix => const DrawMatrixReport(),
  ReportKind.cards => const PilotCardsReport(),
  ReportKind.sheet => const ScoringSheetReport(),
};
