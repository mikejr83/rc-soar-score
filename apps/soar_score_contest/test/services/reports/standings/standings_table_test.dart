import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/standings/standings_options.dart';
import 'package:soar_score_contest/services/reports/standings/standings_report_data.dart';
import 'package:soar_score_contest/services/reports/standings/standings_status.dart';
import 'package:soar_score_contest/services/reports/standings/standings_table.dart';
import 'package:soar_score_contest/services/reports/result_status.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/standings_fixtures.dart';
import '../../../support/workspace_facts_support.dart';

StandingsReportData _data(
  StandingsFixture fixture, {
  int asOf = 2,
  bool details = false,
}) {
  final flights = {
    for (var r = 1; r <= asOf; r++)
      r: {
        for (final f in fixture.roundResults[r]!.flights)
          f.participationId: f.result,
      },
  };
  return StandingsReportData(
    results: fixture.standings[asOf]!,
    flights: flights,
    details: details
        ? {
            for (var r = 1; r <= asOf; r++)
              r: {
                for (final id in flights[r]!.keys)
                  id: const FlightDetail(
                    seconds: 592,
                    landing: 50,
                    height: 105,
                  ),
              },
          }
        : const {},
  );
}

void main() {
  final fixture = StandingsFixture();
  final facts = factsOf(fixture);
  StandingsOptions options(Map<String, String> filters) => StandingsOptions.of({
    ...StandingsOptions.defaults(facts),
    ...filters,
  }, facts);

  group('rows', () {
    final table = StandingsTable.build(
      facts: facts,
      options: options({}),
      data: _data(fixture),
    );

    test('are in the stored order of places', () {
      expect(
        [for (final row in table.rows) row.pilot.listName],
        ['Ray, Bo', 'Fox, Cy', 'Park, Di', 'Lee, Ann'],
      );
      expect([for (final row in table.rows) row.place], [1, 2, 3, 4]);
    });

    test('totals come from the stored standing', () {
      expect(
        [for (final row in table.rows) row.total],
        [1750, 1400, 1200, 900],
      );
    });

    test('raw is the total plus the dropped rounds, penalty deducted', () {
      // Pilot 1 dropped a 500.0 round; pilot 4 lost 50 and dropped nothing.
      expect([for (final row in table.rows) row.raw], [1750, 1400, 1200, 1400]);
    });

    test('percentage is of the winner, with one decimal', () {
      final format = StandingsFormat(1);
      expect(
        [for (final row in table.rows) format.percentage(row.percentage)],
        ['100.0%', '80.0%', '68.6%', '51.4%'],
      );
    });

    test('a dropped round is marked, and only that one', () {
      final lee = table.rows.last;
      expect(lee.cells[1]!.dropped, isFalse);
      expect(lee.cells[2]!.dropped, isTrue);
      expect(lee.cells[2]!.score, 500);
      expect(table.rows.first.cells.values.any((c) => c.dropped), isFalse);
    });

    test('a penalty is shown and the table knows it has one', () {
      expect(table.hasPenalty, isTrue);
      expect(table.rows[2].penalty, 50);
      expect(table.rows.first.penalty, 0);
    });

    test('rounds follow the filter, rank and total do not', () {
      final slice = StandingsTable.build(
        facts: facts,
        options: options({'from': '2'}),
        data: _data(fixture),
      );
      expect(slice.rounds, [2]);
      expect(slice.rows.first.cells.keys, [2]);
      expect(slice.rows.first.total, 1750);
    });
  });

  group('cells', () {
    test('a round with no flight is no score, not a zero', () {
      final data = _data(fixture);
      data.flights[2]!.remove(participationId(3));
      final table = StandingsTable.build(
        facts: facts,
        options: options({}),
        data: data,
      );
      final fox = table.rows.firstWhere((r) => r.pilot.lastName == 'Fox');
      expect(fox.cells[2]!.score, isNull);
      expect(fox.cells[1]!.score, 700);
    });

    test('rounds after a pilot retired are a plain zero', () {
      final retired = factsOf(
        fixture,
        participations: matrixParticipations(retired: {3: 2}),
      );
      final data = _data(fixture);
      data.flights[2]!.remove(participationId(3));
      final table = StandingsTable.build(
        facts: retired,
        options: StandingsOptions.of(
          StandingsOptions.defaults(retired),
          retired,
        ),
        data: data,
      );
      final fox = table.rows.firstWhere((r) => r.pilot.lastName == 'Fox');
      expect(fox.cells[2]!.score, 0);
      expect(StandingsFormat(1).round(0), '0');
    });

    test('flight details are carried only when asked for', () {
      final without = StandingsTable.build(
        facts: facts,
        options: options({}),
        data: _data(fixture, details: true),
      );
      expect(without.rows.first.cells[1]!.detail, isNull);

      final withDetails = StandingsTable.build(
        facts: facts,
        options: options({'det': '1'}),
        data: _data(fixture, details: true),
      );
      expect(withDetails.rows.first.cells[1]!.detail?.seconds, 592);
    });
  });

  group('formatting', () {
    final format = StandingsFormat(1);

    test('scores use the contest decimals with separators', () {
      expect(format.score(1750), '1,750.0');
      expect(StandingsFormat(0).score(1750), '1,750');
      expect(StandingsFormat(2).score(87.5), '87.50');
    });

    test('a zero round score is a plain 0, a penalty a deduction', () {
      expect(format.round(0), '0');
      expect(format.round(987.4), '987.4');
      expect(format.penalty(100), '−100.0');
    });

    test('no percentage without a winner to compare to', () {
      expect(format.percentage(null), '—');
    });

    test('detail lines show a part that was not recorded as an em dash', () {
      final table = StandingsTable.build(
        facts: facts,
        options: options({'det': '1'}),
        data: _data(fixture, details: true),
      );
      expect(
        table.detailLines(
          const FlightDetail(seconds: 592, landing: 50, height: 105),
        ),
        ['9:52', '50', '105m'],
      );
      expect(
        table.detailLines(const FlightDetail(seconds: 65, landing: 42.5)),
        ['1:05', '42.5', '—'],
      );
      expect(table.detailLines(null), ['—', '—', '—']);
    });
  });

  group('status', () {
    test('official when the stored standings are final', () {
      final status = StandingsStatus.of(facts, options({}), _data(fixture));
      expect(status.status, ResultStatus.official);
      expect(status.reason, isNull);
    });

    test('preliminary when the stored standings say so', () {
      final prelim = StandingsFixture(preliminary: true);
      final status = StandingsStatus.of(facts, options({}), _data(prelim));
      expect(status.status, ResultStatus.preliminary);
      expect(status.reason, isNotEmpty);
      expect(status.action?.label, 'Open Scoring');
    });

    test('stale results are preliminary and say why', () {
      final stale = StandingsReportData(
        results: ContestResults(
          asOfRound: 2,
          isStale: true,
          standings: fixture.standings[2]!.standings,
        ),
        flights: _data(fixture).flights,
        details: const {},
      );
      final status = StandingsStatus.of(facts, options({}), stale);
      expect(status.status, ResultStatus.preliminary);
      expect(status.reason, contains('calculated before the latest change'));
    });

    test('missing scores are named by round', () {
      final matrix = drawnMatrix();
      final partial = factsOf(
        fixture,
        scores: scoresFor(matrix, {
          for (var p = 1; p <= 4; p++) (1, p): at(p),
          (2, 1): at(10),
          (2, 2): at(11),
        }),
      );
      final prelim = StandingsFixture(preliminary: true);
      final status = StandingsStatus.of(
        partial,
        StandingsOptions.of(StandingsOptions.defaults(partial), partial),
        _data(prelim),
      );
      expect(status.reason, startsWith('round 2 has 2 missing scores'));
      expect(
        status.reason,
        contains('Turn off Provisional to print rounds 1 to 1'),
      );
      expect(status.action?.round, 2);
    });
  });
}
