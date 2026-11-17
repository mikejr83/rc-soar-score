import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/reports/csv_export/score_export_error.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_source.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/standings_fixtures.dart';

/// A one-read report for [fixture]'s two-round contest: the contest facts,
/// the stored standings as of round 2, and every flight of the two rounds.
ReportData reportOf(StandingsFixture fixture, {int asOf = 2}) {
  return ReportData(
    contest: matrixContest(),
    configuration: matrixConfiguration(),
    participations: matrixParticipations(numbered: true),
    participants: matrixProfiles(),
    teams: matrixTeams(),
    teamMemberships: matrixMemberships(),
    scores: fixture.scores,
    results: fixture.standings[asOf]!,
    roundResults: [for (final round in fixture.roundResults.values) round],
  );
}

ScoreExportOptions allOptions({int to = 2}) => ScoreExportOptions(
  from: 1,
  requestedTo: to,
  to: to,
  lastShown: 2,
  rounds: [1, 2],
  percentage: false,
  raw: false,
  team: false,
  number: false,
  pilotClass: false,
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
      final lee = source.standings.lastWhere(
        (r) => r.pilot.listName == 'Lee, Ann',
      );
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
    test('the contest name and decimal places are carried', () {
      expect(source.contestName, 'Gator Cup F5J');
      expect(source.decimalPlaces, 1);
      expect(source.rounds, [1, 2]);
    });
  });

  group('validation', () {
    test('a read with no stored standing throws', () {
      final report = reportOf(fixture);
      final noStanding = ReportData(
        contest: report.contest,
        configuration: report.configuration,
        participations: report.participations,
        participants: report.participants,
        teams: report.teams,
        teamMemberships: report.teamMemberships,
        scores: report.scores,
        results: null,
        roundResults: report.roundResults,
      );
      expect(
        () => ScoreExportSource.of(noStanding, allOptions()),
        throwsA(isA<ScoreExportError>()),
      );
    });

    test('standings as of a different round than the export throws', () {
      // The standings are as of round 1, but the export shows to round 2.
      expect(
        () => ScoreExportSource.of(reportOf(fixture, asOf: 1), allOptions()),
        throwsA(isA<ScoreExportError>()),
      );
    });

    test('an empty range throws', () {
      final options = ScoreExportOptions(
        from: 3,
        requestedTo: 5,
        to: 0,
        lastShown: 2,
        rounds: const [],
        percentage: false,
        raw: false,
        team: false,
        number: false,
        pilotClass: false,
      );
      expect(
        () => ScoreExportSource.of(reportOf(fixture), options),
        throwsA(isA<ScoreExportError>()),
      );
    });
  });

  group('sort tiebreak', () {
    test('tied flights order by participation id', () {
      // Two flights in group 1 with the same score: the order is decided by
      // the participation id, not the unstable list order.
      final tie = RoundResults(
        ordinal: 1,
        flights: [
          RoundFlightResult(
            group: 1,
            result: flight(1, 1, 500, placeholder: Id.create()),
          ),
          RoundFlightResult(
            group: 1,
            result: flight(3, 1, 500, placeholder: Id.create()),
          ),
        ],
      );
      final report = ReportData(
        contest: matrixContest(),
        configuration: matrixConfiguration(),
        participations: matrixParticipations(numbered: true),
        participants: matrixProfiles(),
        teams: matrixTeams(),
        teamMemberships: matrixMemberships(),
        scores: fixture.scores,
        results: fixture.standings[1]!,
        roundResults: [tie],
      );
      final source = ScoreExportSource.of(report, allOptions(to: 1));
      expect(
        [for (final f in source.flights) f.pilot.participationId.value],
        [participationId(1).value, participationId(3).value],
      );
    });
  });
}
