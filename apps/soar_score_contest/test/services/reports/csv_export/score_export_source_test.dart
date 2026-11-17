import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_source.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/standings_fixtures.dart';

/// A one-read report for [fixture]'s two-round contest: the contest facts,
/// the stored standings, and every flight of the two rounds.
ReportData reportOf(StandingsFixture fixture) {
  return ReportData(
    contest: matrixContest(),
    configuration: matrixConfiguration(),
    participations: matrixParticipations(numbered: true),
    participants: matrixProfiles(),
    teams: matrixTeams(),
    teamMemberships: matrixMemberships(),
    scores: fixture.scores,
    results: fixture.standings[2]!,
    roundResults: [
      for (final round in fixture.roundResults.values) round,
    ],
  );
}

ScoreExportOptions allOptions() => const ScoreExportOptions(
  from: 1,
  to: 2,
  rounds: [1, 2],
  provisional: false,
  percentage: false,
  raw: false,
  team: false,
  number: false,
  pilotClass: false,
  details: false,
);

void main() {
  final fixture = StandingsFixture();
  final source = ScoreExportSource.of(reportOf(fixture), allOptions());

  group('standings view', () {
    test('one row per pilot, in the stored rank order', () {
      expect(source.standings.length, 4);
      expect(
        [for (final row in source.standings) row.pilot.listName],
        ['Ray, Bo', 'Fox, Cy', 'Park, Di', 'Lee, Ann'],
      );
      expect([for (final row in source.standings) row.place], [1, 2, 3, 4]);
    });

    test('total, raw and penalty come from the stored standing', () {
      final byName = {for (final r in source.standings) r.pilot.listName: r};
      expect(byName['Ray, Bo']!.total, 1750);
      expect(byName['Ray, Bo']!.raw, 1750);
      expect(byName['Lee, Ann']!.total, 900);
      expect(byName['Lee, Ann']!.raw, 1400);
      expect(byName['Lee, Ann']!.penalty, 0);
      expect(byName['Park, Di']!.total, 1200);
      expect(byName['Park, Di']!.raw, 1200);
      expect(byName['Park, Di']!.penalty, 50);
    });

    test('percentage is of the winner', () {
      final byName = {for (final r in source.standings) r.pilot.listName: r};
      expect(byName['Ray, Bo']!.percentage, 100);
      expect(byName['Fox, Cy']!.percentage, 80);
      expect(byName['Lee, Ann']!.percentage, closeTo(51.4286, 0.0001));
    });

    test('a cell is the pilot\'s selected round score', () {
      final byName = {for (final r in source.standings) r.pilot.listName: r};
      final ray = byName['Ray, Bo']!;
      expect(ray.cells[1]!.score, 800);
      expect(ray.cells[2]!.score, 950);
      expect(ray.cells[1]!.dropped, isFalse);
    });

    test('a dropped round keeps its value and is marked dropped', () {
      final lee = source.standings.lastWhere((r) => r.pilot.listName == 'Lee, Ann');
      expect(lee.cells[2]!.score, 500);
      expect(lee.cells[2]!.dropped, isTrue);
    });
  });

  group('flight view', () {
    test('one row per flight, every flight not only the selected one', () {
      expect(source.flights.length, 8);
    });

    test('rows are ordered by round, then group, then score', () {
      expect(
        [for (final f in source.flights) '${f.round}${f.group}'],
        ['1A', '1A', '1B', '1B', '2A', '2A', '2B', '2B'],
      );
    });

    test('the selected flag marks the counting flight', () {
      expect(source.flights.every((f) => f.selected), isTrue);
    });

    test('the round score is the flight group score', () {
      expect(
        [for (final f in source.flights) f.roundScore],
        [900, 800, 700, 600, 700, 500, 950, 650],
      );
    });

    test('time and height come from the official score components', () {
      for (final flight in source.flights) {
        expect(flight.seconds, 592);
        expect(flight.height, 105);
      }
    });

    test('landing points come from the flight result', () {
      expect(
        [for (final f in source.flights) f.landing],
        [50, 50, 50, 50, 50, 50, 50, 50],
      );
    });

    test('place and total are denormalized onto every flight row', () {
      final ray = source.flights
          .where((f) => f.pilot.listName == 'Ray, Bo')
          .toList();
      expect(ray.map((f) => f.place), [1, 1]);
      expect(ray.map((f) => f.total), [1750, 1750]);
    });
  });

  group('facts', () {
    test('the discipline resolves from the system profile', () {
      // matrixConfiguration uses a profile id that is not a system one, so
      // the discipline is unknown; the branch still degrades to no height.
      expect(source.discipline, isNull);
      expect(source.hasLaunchHeight, isFalse);
    });

    test('the contest name and decimal places are carried', () {
      expect(source.contestName, 'Gator Cup F5J');
      expect(source.decimalPlaces, 1);
      expect(source.rounds, [1, 2]);
    });

    test('a system F5J configuration records a launch height', () {
      final report = reportOf(fixture);
      final config = ContestConfigurationRevision(
        id: report.configuration!.id,
        contestId: report.contest.id,
        revisionNumber: report.configuration!.revisionNumber,
        disciplineProfileId: SystemDisciplineProfiles.f5jId,
        config: report.configuration!.config,
        createdBy: report.configuration!.createdBy,
        createdAt: report.configuration!.createdAt,
      );
      final f5j = ScoreExportSource.of(
        ReportData(
          contest: report.contest,
          configuration: config,
          participations: report.participations,
          participants: report.participants,
          teams: report.teams,
          teamMemberships: report.teamMemberships,
          scores: report.scores,
          results: report.results,
          roundResults: report.roundResults,
        ),
        allOptions(),
      );
      expect(f5j.discipline, DisciplineType.f5j);
      expect(f5j.hasLaunchHeight, isTrue);
    });
  });
}
