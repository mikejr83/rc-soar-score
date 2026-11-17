import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_source.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/reports/standings/standings_options.dart';
import 'package:soar_score_contest/services/reports/standings/standings_report_data.dart';
import 'package:soar_score_contest/services/reports/standings/standings_table.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/standings_fixtures.dart';

/// The shared derivation must not drift from the viewer: the CSV engine and
/// the Overall Standings report read the same contest and must agree on the
/// rounds, the option columns, the decimals, and every pilot's numbers.
void main() {
  final fixture = StandingsFixture();

  // A configuration that uses teams, numbers and classes, with two decimals,
  // so both sides populate the pilot's identity the same way.
  final core = const {
    'teams_enabled': true,
    'team_pilot_count': 2,
    'participant_numbers_enabled': true,
    'classes_enabled': true,
    'decimal_places': 2,
  };
  final config = matrixConfiguration(core);
  final participations = matrixParticipations(numbered: true);
  final data = MatrixPageData(
    contest: matrixContest(state: LifecycleState.running),
    configuration: config,
    participations: participations,
    profiles: matrixProfiles(),
    teams: matrixTeams(),
    memberships: matrixMemberships(),
    matrix: fixture.matrix,
  );
  final scores = fixture.scores;
  final facts = ReportsFacts.derive(
    data: data,
    scores: scores,
    workspace: WorkspaceFacts.derive(data: data, scores: scores),
  );

  // The same filters drive both the viewer's options and the export's.
  final filters = {
    ...StandingsOptions.defaults(facts),
    'raw': '1',
    'team': '1',
    'num': '1',
    'cls': '1',
  };

  // The viewer's side: the report's options and table.
  final viewerOptions = StandingsOptions.of(filters, facts);
  final flights = {
    for (var r = 1; r <= 2; r++)
      r: {
        for (final f in fixture.roundResults[r]!.flights)
          f.participationId: f.result,
      },
  };
  final reportData = StandingsReportData(
    results: fixture.standings[2]!,
    flights: flights,
    details: const {},
  );
  final table = StandingsTable.build(
    facts: facts,
    options: viewerOptions,
    data: reportData,
  );

  // The engine's side: one read and the same filters.
  final read = ReportData(
    contest: data.contest,
    configuration: config,
    participations: participations,
    participants: matrixProfiles(),
    teams: matrixTeams(),
    teamMemberships: matrixMemberships(),
    scores: scores,
    results: fixture.standings[2]!,
    roundResults: [for (final r in fixture.roundResults.values) r],
  );
  final exportOptions = ScoreExportOptions.of(filters, facts);
  final source = ScoreExportSource.of(read, exportOptions);

  test('the options agree on the rounds and the columns', () {
    expect(source.rounds, viewerOptions.rounds);
    expect(exportOptions.from, viewerOptions.from);
    expect(exportOptions.to, viewerOptions.to);
    expect(exportOptions.percentage, viewerOptions.percentage);
    expect(exportOptions.raw, viewerOptions.raw);
    expect(exportOptions.team, viewerOptions.team);
    expect(exportOptions.number, viewerOptions.number);
    expect(exportOptions.pilotClass, viewerOptions.pilotClass);
    expect(source.decimalPlaces, facts.decimalPlaces);
  });

  test('every pilot agrees on identity, totals and round scores', () {
    final viewerByPilot = {
      for (final row in table.rows) row.pilot.participationId: row,
    };
    final engineByPilot = {
      for (final row in source.standings) row.pilot.participationId: row,
    };
    expect(engineByPilot.keys.toSet(), viewerByPilot.keys.toSet());

    for (final entry in engineByPilot.entries) {
      final engine = entry.value;
      final viewer = viewerByPilot[entry.key]!;
      // Identity.
      expect(engine.pilot.listName, viewer.pilot.listName);
      expect(engine.pilot.number, viewer.pilot.number);
      expect(engine.pilot.team, viewer.pilot.team);
      expect(engine.pilot.className, viewer.pilot.className);
      expect(engine.pilot.retiredAtRound, viewer.pilot.retiredAtRound);
      // The stored standing's numbers.
      expect(engine.place, viewer.place);
      expect(engine.total, viewer.total);
      expect(engine.raw, viewer.raw);
      expect(engine.penalty, viewer.penalty);
      expect(engine.percentage, moreOrLessEquals(viewer.percentage!));
      // Each shown round's score and drop.
      for (final round in viewerOptions.rounds) {
        expect(engine.cells[round]?.score, viewer.cells[round]?.score);
        expect(engine.cells[round]?.dropped, viewer.cells[round]?.dropped);
      }
    }
  });
}
