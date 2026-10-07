import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

List<DrawPilot> _pilots(int count, {int teams = 0}) => [
  for (var i = 1; i <= count; i++)
    DrawPilot(_id(i), teamId: teams == 0 ? null : _id(1000 + i % teams)),
];

DrawResult _draw(
  List<DrawPilot> pilots, {
  int rounds = 6,
  int groups = 3,
  bool teamProtection = false,
  LaneMode laneMode = LaneMode.none,
  int seed = 5,
  int seedCount = 3,
}) => const DrawEngine().generate(
  pilots: pilots,
  rounds: rounds,
  groupsPerRound: groups,
  teamProtection: teamProtection,
  laneMode: laneMode,
  seed: seed,
  seedCount: seedCount,
  attemptsPerRound: 5,
  iterationsPerPlacement: 60,
);

List<List<List<Id>>> _ids(DrawResult result) => [
  for (final round in result.rounds)
    [
      for (final group in round)
        [for (final slot in group) slot.pilot.participationId],
    ],
];

void main() {
  group('DrawEngine', () {
    test('drawing again with the winning seed and one run gives the same '
        'matrix', () {
      final pilots = _pilots(15);
      final several = _draw(pilots);

      final again = _draw(pilots, seed: several.seed, seedCount: 1);

      expect(_ids(again), _ids(several));
    });

    test('is reproducible from the seed', () {
      final pilots = _pilots(12);

      expect(_ids(_draw(pilots)), _ids(_draw(pilots)));
      expect(_ids(_draw(pilots)), isNot(_ids(_draw(pilots, seed: 6))));
    });

    test('more seeds are never worse than the first run', () {
      final pilots = _pilots(15);
      for (var seed = 1; seed <= 4; seed++) {
        final one = _draw(pilots, seed: seed, seedCount: 1);
        final many = _draw(pilots, seed: seed, seedCount: 5);

        final ones = MatchupStats.of(one.rounds, teamProtection: false);
        final manys = MatchupStats.of(many.rounds, teamProtection: false);
        expect(manys.compareQuality(ones), lessThanOrEqualTo(0));
      }
    });

    test('keeps teammates apart', () {
      final pilots = _pilots(18, teams: 6);
      final result = _draw(pilots, teamProtection: true);

      for (final round in result.rounds) {
        for (final group in round) {
          final teams = [for (final slot in group) slot.pilot.teamId];
          expect(teams.toSet(), hasLength(teams.length));
        }
      }
    });

    test('reports the fairness figures, with a score from 0 to 100', () {
      final result = _draw(_pilots(15));

      final fairness = result.fairness;
      expect(fairness['feasible_pairs'], 15 * 14 ~/ 2);
      expect(fairness['unmet_opponent_count'], isA<int>());
      expect(fairness['fairness_score'], inInclusiveRange(0, 100));
      expect(fairness['matchup_cost'], greaterThanOrEqualTo(0));
      expect(
        fairness['matchup_cost'] as double,
        lessThanOrEqualTo(fairness['matchup_cost_random_average'] as double),
      );
      expect(fairness, isNot(contains('lane_uniformity_index')));
    });

    test('reports the lane uniformity index when there are lanes', () {
      final result = _draw(_pilots(12), laneMode: LaneMode.random);

      expect(result.fairness['lane_uniformity_index'], isA<double>());
    });

    test('the same contest gets the same random baseline', () {
      final a = _draw(_pilots(12), seed: 1).fairness;
      final b = _draw(_pilots(12), seed: 2).fairness;

      expect(
        a['matchup_cost_random_average'],
        b['matchup_cost_random_average'],
      );
    });

    test('rejects a seed count outside 1 to 20', () {
      expect(() => _draw(_pilots(6), seedCount: 0), throwsArgumentError);
      expect(() => _draw(_pilots(6), seedCount: 21), throwsArgumentError);
    });

    test('rejects settings that cannot be drawn', () {
      expect(() => _draw(_pilots(3), groups: 4), throwsArgumentError);
    });

    test('draws the same matrix on every platform (recorded reference)', () {
      final pilots = _pilots(12, teams: 4);
      final result = const DrawEngine().generate(
        pilots: pilots,
        rounds: 4,
        groupsPerRound: 3,
        teamProtection: true,
        laneMode: LaneMode.random,
        seed: 2024,
        seedCount: 2,
        attemptsPerRound: 5,
        iterationsPerPlacement: 50,
      );

      String tag(DrawSlot slot) {
        final id = slot.pilot.participationId.value;
        return '${id.substring(id.length - 2)}:${slot.lane}';
      }

      expect(result.seed, 2024);
      expect(
        [
          for (final round in result.rounds.take(2))
            [
              for (final group in round) [for (final slot in group) tag(slot)],
            ],
        ],
        [
          [
            ['06:4', '08:1', '07:3', '09:2'],
            ['02:4', '04:2', '03:3', '01:1'],
            ['0a:1', '05:3', '0c:4', '0b:2'],
          ],
          [
            ['09:4', '03:2', '02:1', '0c:3'],
            ['04:1', '07:2', '05:4', '06:3'],
            ['0a:3', '08:2', '01:4', '0b:1'],
          ],
        ],
      );
    });
  });
}
