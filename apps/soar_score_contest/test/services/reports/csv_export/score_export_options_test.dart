import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/standings_fixtures.dart';

void main() {
  final fixture = StandingsFixture();
  final facts = factsOf(fixture);

  ScoreExportOptions of(Map<String, String> filters) => ScoreExportOptions.of(
    {
      ...ScoreExportOptions.defaults(facts),
      ...filters,
    },
    facts,
  );

  test('defaults show every scored round', () {
    final options = of(const {});
    expect(options.from, 1);
    expect(options.to, 2);
    expect(options.rounds, [1, 2]);
    expect(options.provisional, isFalse);
    expect(options.percentage, isTrue);
    expect(options.raw, isFalse);
    expect(options.team, isFalse);
    expect(options.number, isFalse);
    expect(options.pilotClass, isFalse);
    expect(options.details, isFalse);
  });

  test('a round range is honoured', () {
    expect(of(const {'from': '2'}).rounds, [2]);
    expect(of(const {'to': '1'}).rounds, [1]);
  });

  test('column options toggle', () {
    final options = of(const {
      'pct': '0',
      'raw': '1',
      'det': '1',
    });
    expect(options.percentage, isFalse);
    expect(options.raw, isTrue);
    expect(options.details, isTrue);
  });

  test('a key the contest does not use stays off', () {
    // The fixture has no teams, numbers or classes enabled.
    final options = of(const {'team': '1', 'num': '1', 'cls': '1'});
    expect(options.team, isFalse);
    expect(options.number, isFalse);
    expect(options.pilotClass, isFalse);
  });

  test('a completed contest is never provisional', () {
    final completed = factsOf(fixture, state: LifecycleState.completed);
    expect(ScoreExportOptions.of(const {}, completed).provisional, isFalse);
  });
}
