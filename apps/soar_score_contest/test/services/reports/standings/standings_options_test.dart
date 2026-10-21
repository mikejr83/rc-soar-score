import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/services/reports/standings/standings_options.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/standings_fixtures.dart';
import '../../../support/workspace_facts_support.dart';

void main() {
  final fixture = StandingsFixture();

  group('defaults', () {
    test('all rounds, no provisional once every round is scored', () {
      final facts = factsOf(fixture);
      final options = StandingsOptions.of(
        StandingsOptions.defaults(facts),
        facts,
      );
      expect(options.from, 1);
      expect(options.to, 2);
      expect(options.provisional, isFalse);
      expect(options.percentage, isTrue);
      expect(options.raw, isFalse);
      expect(options.details, isFalse);
      expect(options.rounds, [1, 2]);
      expect(options.isRange, isFalse);
    });

    test('provisional starts on while a round is partly scored', () {
      final matrix = drawnMatrix();
      final scores = scoresFor(matrix, {
        for (var p = 1; p <= 4; p++) (1, p): at(p),
        (2, 1): at(10),
      });
      final facts = factsOf(fixture, scores: scores);
      final options = StandingsOptions.of(
        StandingsOptions.defaults(facts),
        facts,
      );
      expect(options.provisional, isTrue);
      expect(options.lastShown, 2);
      expect(facts.lastFullyScoredRound, 1);
    });

    test('a completed contest has nothing provisional, even if asked', () {
      final matrix = drawnMatrix();
      final scores = scoresFor(matrix, {
        for (var p = 1; p <= 4; p++) (1, p): at(p),
        (2, 1): at(10),
      });
      final facts = factsOf(
        fixture,
        scores: scores,
        state: LifecycleState.completed,
      );
      expect(StandingsOptions.provisionalApplies(facts), isFalse);
      expect(StandingsOptions.of({'prov': '1'}, facts).provisional, isFalse);
      expect(StandingsOptions.defaults(facts)['prov'], '0');
    });

    test('provisional off shows only fully scored rounds', () {
      final matrix = drawnMatrix();
      final scores = scoresFor(matrix, {
        for (var p = 1; p <= 4; p++) (1, p): at(p),
        (2, 1): at(10),
      });
      final facts = factsOf(fixture, scores: scores);
      final options = StandingsOptions.of({'prov': '0'}, facts);
      expect(options.lastShown, 1);
      expect(options.to, 1);
      expect(options.rounds, [1]);
    });
  });

  group('the round range', () {
    final facts = factsOf(fixture);

    test('the upper bound is the standings round', () {
      final options = StandingsOptions.of({'from': '2', 'to': '2'}, facts);
      expect(options.to, 2);
      expect(options.rounds, [2]);
      expect(options.isRange, isTrue);
      expect(options.summary, 'Rounds 2');
    });

    test('a lower bound above the upper bound is invalid', () {
      final options = StandingsOptions.of({'from': '2', 'to': '1'}, facts);
      expect(options.check(facts), isA<ReportInvalid>());
    });

    test('a range with nothing to show is empty, with a way out', () {
      final matrix = drawnMatrix();
      final partial = factsOf(
        fixture,
        scores: scoresFor(matrix, {
          for (var p = 1; p <= 4; p++) (1, p): at(p),
          (2, 1): at(10),
        }),
      );
      final options = StandingsOptions.of({
        'from': '2',
        'to': '2',
        'prov': '0',
      }, partial);
      final check = options.check(partial);
      expect(check, isA<ReportEmpty>());
      expect((check as ReportEmpty).title, 'No scores in rounds 2');
      expect(check.body, contains('Turn Provisional on'));
      expect(check.body, contains('rounds 1 to 1'));
    });

    test('a valid range is fine', () {
      expect(
        StandingsOptions.of({'from': '1', 'to': '2'}, facts).check(facts),
        ReportCheck.ok,
      );
    });
  });

  group('options the contest does not use', () {
    test('team, number and class stay off without the contest option', () {
      final facts = factsOf(fixture);
      final options = StandingsOptions.of({
        'team': '1',
        'num': '1',
        'cls': '1',
      }, facts);
      expect(options.team, isFalse);
      expect(options.number, isFalse);
      expect(options.pilotClass, isFalse);
    });

    test('pilot numbers and classes follow the contest options', () {
      final facts = factsOf(
        fixture,
        core: const {
          'participant_numbers_enabled': true,
          'classes_enabled': true,
        },
      );
      final options = StandingsOptions.of({'num': '1', 'cls': '1'}, facts);
      expect(options.number, isTrue);
      expect(options.pilotClass, isTrue);
    });
  });

  group('cancelled rounds', () {
    final cancelled = StandingsFixture(round2Cancelled: true);
    final facts = factsOf(cancelled);

    test('are not rounds the report can show', () {
      expect(facts.roundOrdinals, [1]);
      final options = StandingsOptions.of(
        StandingsOptions.defaults(facts),
        facts,
      );
      expect(options.rounds, [1]);
      expect(options.to, 1);
    });

    test(
      'an upper bound on a cancelled round falls back to the last round',
      () {
        final options = StandingsOptions.of({'to': '2'}, facts);
        expect(options.rounds, [1]);
        expect(options.to, 1);
      },
    );

    test('a range with only cancelled rounds is empty', () {
      final options = StandingsOptions.of({'from': '2', 'to': '2'}, facts);
      expect(options.rounds, isEmpty);
      expect(options.check(facts), isA<ReportEmpty>());
    });
  });
}
