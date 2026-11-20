import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/standings_fixtures.dart';
import '../../../support/workspace_facts_support.dart';

void main() {
  final fixture = StandingsFixture();
  final facts = factsOf(fixture);

  ScoreExportOptions of(Map<String, String> filters) => ScoreExportOptions.of({
    ...ScoreExportOptions.defaults(facts),
    ...filters,
  }, facts);

  test('defaults show every scored round', () {
    final options = of(const {});
    expect(options.from, 1);
    expect(options.to, 2);
    expect(options.rounds, [1, 2]);
    expect(options.percentage, isTrue);
    expect(options.raw, isFalse);
    expect(options.team, isFalse);
    expect(options.number, isFalse);
    expect(options.pilotClass, isFalse);
    expect(options.check(), isNull);
  });

  test('a round range is honoured', () {
    expect(of(const {'from': '2'}).rounds, [2]);
    expect(of(const {'to': '1'}).rounds, [1]);
  });

  test('column options toggle', () {
    final options = of(const {'pct': '0', 'raw': '1'});
    expect(options.percentage, isFalse);
    expect(options.raw, isTrue);
  });

  test('a key the contest does not use stays off', () {
    // The fixture has no teams, numbers or classes enabled.
    final options = of(const {'team': '1', 'num': '1', 'cls': '1'});
    expect(options.team, isFalse);
    expect(options.number, isFalse);
    expect(options.pilotClass, isFalse);
  });

  test('a from above the to is refused', () {
    final options = of(const {'from': '2', 'to': '1'});
    expect(options.check(), isNotNull);
  });

  test('a range with no scored round is refused', () {
    // The fixture scores only rounds 1 and 2, so a range past them is empty.
    final options = of(const {'from': '3', 'to': '5'});
    expect(options.check(), isNotNull);
  });

  test('a completed contest exports later rounds after a gap', () {
    final completed = factsOf(
      fixture,
      state: LifecycleState.completed,
      scores: scoresFor(drawnMatrix(), {(1, 1): at(1), (2, 1): at(2)}),
    );
    final defaults = ScoreExportOptions.defaults(completed);
    expect(defaults['prov'], '0');
    final options = ScoreExportOptions.of(defaults, completed);
    expect(options.rounds, [1, 2]);
    expect(options.check(), isNull);
  });

  test('a completed contest without a snapshot has no standings to export', () {
    final noSnapshots = StandingsFixture()..standings.clear();
    final completed = factsOf(noSnapshots, state: LifecycleState.completed);
    final options = ScoreExportOptions.of(const {}, completed);

    expect(completed.lastScoredRound, 2);
    expect(options.rounds, isEmpty);
    expect(
      options.check(),
      'No standings are stored for the requested rounds.',
    );
  });
}
