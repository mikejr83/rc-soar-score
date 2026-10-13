import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

List<DrawPilot> _pilots(int count, {int teams = 0}) => [
  for (var i = 1; i <= count; i++)
    DrawPilot(_id(i), teamId: teams == 0 ? null : _id(1000 + i % teams)),
];

typedef Rounds = List<List<List<DrawSlot>>>;

Rounds _start(
  List<DrawPilot> pilots, {
  int rounds = 8,
  int groups = 3,
  bool teamProtection = false,
  LaneMode laneMode = LaneMode.none,
  int seed = 1,
}) => const BasicDraw().generate(
  pilots: pilots,
  rounds: rounds,
  groupsPerRound: groups,
  teamProtection: teamProtection,
  laneMode: laneMode,
  random: SeededRandom(seed),
  attemptsPerRound: 1,
);

Rounds _improve(
  List<DrawPilot> pilots,
  Rounds start, {
  bool teamProtection = false,
  LaneMode laneMode = LaneMode.none,
  int seed = 2,
  int iterations = 100,
}) => const DrawOptimizer().improve(
  pilots: pilots,
  start: start,
  teamProtection: teamProtection,
  laneMode: laneMode,
  random: SeededRandom(seed),
  iterationsPerPlacement: iterations,
);

List<List<List<Id>>> _ids(Rounds rounds) => [
  for (final round in rounds)
    [
      for (final group in round)
        [for (final slot in group) slot.pilot.participationId],
    ],
];

void main() {
  group('DrawOptimizer', () {
    test('keeps every pilot once per round and the groups balanced', () {
      final pilots = _pilots(14);
      final improved = _improve(pilots, _start(pilots, groups: 4));

      for (final round in improved) {
        expect(round, hasLength(4));
        final sizes = [for (final group in round) group.length]..sort();
        expect(sizes.last - sizes.first, lessThanOrEqualTo(1));
        expect({
          for (final group in round) ...group.map((s) => s.pilot),
        }, hasLength(14));
      }
    });

    test('improves the draw for each of five seeds', () {
      final pilots = _pilots(15);
      var better = 0;
      for (var seed = 1; seed <= 5; seed++) {
        final start = _start(pilots, seed: seed);
        final improved = _improve(pilots, start, seed: seed);
        final before = MatchupStats.of(start, teamProtection: false);
        final after = MatchupStats.of(improved, teamProtection: false);
        expect(after.compareQuality(before), lessThanOrEqualTo(0));
        if (after.compareQuality(before) < 0) better++;
      }
      expect(better, greaterThanOrEqualTo(4));
    });

    test('keeps teammates in different groups under team protection', () {
      final pilots = _pilots(18, teams: 6); // six teams of three
      final improved = _improve(
        pilots,
        _start(pilots, teamProtection: true),
        teamProtection: true,
      );

      for (final round in improved) {
        for (final group in round) {
          final teams = [for (final slot in group) slot.pilot.teamId];
          expect(teams.toSet(), hasLength(teams.length));
        }
      }
    });

    test('is reproducible from the seed', () {
      final pilots = _pilots(12);
      final start = _start(pilots);

      expect(_ids(_improve(pilots, start)), _ids(_improve(pilots, start)));
      expect(
        _ids(_improve(pilots, start)),
        isNot(_ids(_improve(pilots, start, seed: 99))),
      );
    });

    test('leaves a draw with a single group as it is', () {
      final pilots = _pilots(5);
      final start = _start(pilots, groups: 1, rounds: 3);

      expect(_ids(_improve(pilots, start)), _ids(start));
    });

    test('lanes stay unique in a group, within 1 to the largest group', () {
      final pilots = _pilots(14);
      final improved = _improve(
        pilots,
        _start(pilots, groups: 4, laneMode: LaneMode.random),
        laneMode: LaneMode.random,
      );

      for (final round in improved) {
        for (final group in round) {
          final lanes = [for (final slot in group) slot.lane!];
          expect(lanes.toSet(), hasLength(lanes.length));
          expect(lanes, everyElement(inInclusiveRange(1, 4)));
        }
      }
    });

    test('balances how often each pilot flies from each lane', () {
      final pilots = _pilots(12);
      final start = _start(pilots, rounds: 12, laneMode: LaneMode.random);
      final improved = _improve(pilots, start, laneMode: LaneMode.random);

      double spread(Rounds rounds) =>
          drawFairness(rounds, teamProtection: false)['lane_uniformity_index']!
              as double;
      expect(spread(improved), lessThan(spread(start)));
    });

    test('leaves lanes empty when the lane mode is None', () {
      final pilots = _pilots(9);
      final improved = _improve(pilots, _start(pilots));

      expect(
        [
          for (final round in improved)
            for (final g in round) ...g,
        ].map((s) => s.lane),
        everyElement(isNull),
      );
    });
  });
}
