import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

List<DrawPilot> _pilots(int count, {Map<int, int> teams = const {}}) => [
  for (var i = 1; i <= count; i++)
    DrawPilot(_id(i), teamId: teams[i] == null ? null : _id(1000 + teams[i]!)),
];

List<List<List<DrawSlot>>> _draw(
  List<DrawPilot> pilots, {
  int rounds = 4,
  int groups = 3,
  bool teamProtection = false,
  LaneMode laneMode = LaneMode.none,
  int seed = 7,
  int attempts = BasicDraw.defaultAttemptsPerRound,
}) => const BasicDraw().generate(
  pilots: pilots,
  rounds: rounds,
  groupsPerRound: groups,
  teamProtection: teamProtection,
  laneMode: laneMode,
  random: SeededRandom(seed),
  attemptsPerRound: attempts,
);

void main() {
  group('BasicDraw', () {
    test('flies every pilot once in every round', () {
      final pilots = _pilots(10);
      final rounds = _draw(pilots);

      expect(rounds, hasLength(4));
      for (final round in rounds) {
        expect(round, hasLength(3));
        final flown = [
          for (final group in round)
            for (final slot in group) slot.pilot.participationId,
        ];
        expect(flown.toSet(), {for (final p in pilots) p.participationId});
        expect(flown, hasLength(10));
      }
    });

    test('balances group sizes to within one pilot', () {
      for (final count in [7, 10, 11, 12]) {
        for (final round in _draw(_pilots(count), groups: 3)) {
          final sizes = [for (final group in round) group.length];
          expect(
            sizes.reduce((a, b) => a > b ? a : b) -
                sizes.reduce((a, b) => a < b ? a : b),
            lessThanOrEqualTo(1),
          );
          expect(sizes.fold<int>(0, (a, b) => a + b), count);
        }
      }
    });

    test('is reproducible from the seed and differs for another seed', () {
      List<List<List<Id>>> ids(int seed) => [
        for (final round in _draw(_pilots(12), seed: seed))
          [
            for (final group in round)
              [for (final slot in group) slot.pilot.participationId],
          ],
      ];

      expect(ids(5), ids(5));
      expect(ids(5), isNot(ids(6)));
    });

    test('leaves lanes empty when the lane mode is None', () {
      final rounds = _draw(_pilots(9));
      expect([
        for (final round in rounds)
          for (final group in round)
            for (final slot in group) slot.lane,
      ], everyElement(isNull));
    });

    test('gives each group distinct lanes from 1 to its size', () {
      final rounds = _draw(_pilots(11), laneMode: LaneMode.random);
      for (final round in rounds) {
        for (final group in round) {
          expect([for (final slot in group) slot.lane]..sort(), [
            for (var i = 1; i <= group.length; i++) i,
          ]);
        }
      }
    });

    test('keeps teammates in different groups under team protection', () {
      final pilots = _pilots(
        12,
        teams: {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 7: 3, 8: 3},
      );
      for (var seed = 0; seed < 25; seed++) {
        final rounds = _draw(
          pilots,
          rounds: 6,
          groups: 3,
          teamProtection: true,
          seed: seed,
        );
        for (final round in rounds) {
          for (final group in round) {
            final teams = [
              for (final slot in group)
                if (slot.pilot.teamId != null) slot.pilot.teamId,
            ];
            expect(teams.toSet(), hasLength(teams.length));
          }
        }
      }
    });

    test('can seat a team as large as the number of groups', () {
      final pilots = _pilots(9, teams: {1: 1, 2: 1, 3: 1});
      final rounds = _draw(pilots, groups: 3, teamProtection: true);
      for (final round in rounds) {
        for (final group in round) {
          expect(
            group.where((slot) => slot.pilot.teamId != null),
            hasLength(1),
          );
        }
      }
    });

    test('rejects a team larger than the number of groups', () {
      final pilots = _pilots(9, teams: {1: 1, 2: 1, 3: 1, 4: 1});
      expect(
        () => _draw(pilots, groups: 3, teamProtection: true),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('at least 4 groups'),
          ),
        ),
      );
    });

    test('ignores teams when team protection is off', () {
      final pilots = _pilots(6, teams: {1: 1, 2: 1, 3: 1, 4: 1});
      expect(() => _draw(pilots, groups: 2), returnsNormally);
    });

    test('rejects settings that cannot be drawn', () {
      expect(() => _draw(_pilots(5), rounds: 0), throwsArgumentError);
      expect(() => _draw(_pilots(5), groups: 0), throwsArgumentError);
      expect(() => _draw(_pilots(5), groups: 6), throwsArgumentError);
      expect(() => _draw(const []), throwsArgumentError);
    });
  });

  group('attempts per round', () {
    double meanDeviation(int attempts) {
      var total = 0.0;
      for (var seed = 1; seed <= 20; seed++) {
        final rounds = _draw(
          _pilots(15),
          rounds: 6,
          groups: 3,
          seed: seed,
          attempts: attempts,
        );
        total +=
            drawFairness(
                  rounds,
                  teamProtection: false,
                )['mean_absolute_deviation']!
                as double;
      }
      return total / 20;
    }

    test('more attempts make the draw fairer', () {
      expect(meanDeviation(10), lessThan(meanDeviation(1)));
    });

    test('a draw with several attempts is still reproducible', () {
      final a = _draw(_pilots(12), attempts: 5);
      final b = _draw(_pilots(12), attempts: 5);

      List<List<List<Id>>> ids(List<List<List<DrawSlot>>> rounds) => [
        for (final round in rounds)
          [
            for (final group in round)
              [for (final slot in group) slot.pilot.participationId],
          ],
      ];
      expect(ids(a), ids(b));
    });

    test('keep teammates apart whatever the attempts', () {
      final rounds = _draw(
        _pilots(12, teams: {1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2}),
        groups: 3,
        teamProtection: true,
        attempts: 25,
      );

      for (final round in rounds) {
        for (final group in round) {
          final teams = [
            for (final slot in group)
              if (slot.pilot.teamId != null) slot.pilot.teamId,
          ];
          expect(teams.toSet(), hasLength(teams.length));
        }
      }
    });

    test('rejects a count outside 1 to 200', () {
      expect(() => _draw(_pilots(6), attempts: 0), throwsArgumentError);
      expect(() => _draw(_pilots(6), attempts: 201), throwsArgumentError);
    });
  });

  group('drawFairness', () {
    test('counts how often pilots meet', () {
      // Two rounds of one group of three: every pair meets twice.
      final rounds = _draw(_pilots(3), rounds: 2, groups: 1);
      expect(drawFairness(rounds, teamProtection: false), {
        'feasible_pairs': 3,
        'max_duplicate_matchups': 2,
        'matchup_histogram': {'2': 3},
        'unmet_opponent_count': 0,
        'mean_absolute_deviation': 0.0,
      });
    });

    test('counts pairs that never meet', () {
      final rounds = _draw(_pilots(4), rounds: 1, groups: 2);
      final fairness = drawFairness(rounds, teamProtection: false);
      expect(fairness['max_duplicate_matchups'], 1);
      expect(fairness['matchup_histogram'], {'0': 4, '1': 2});
      expect(fairness['unmet_opponent_count'], 4);
    });

    test('leaves teammates out under team protection', () {
      // Two teams of two among four pilots in two groups, one round: the
      // two pairs of teammates cannot meet, so only 4 pairs can.
      final pilots = _pilots(4, teams: {1: 1, 2: 1, 3: 2, 4: 2});
      final rounds = _draw(pilots, rounds: 1, groups: 2, teamProtection: true);

      final fairness = drawFairness(rounds, teamProtection: true);

      expect(fairness['feasible_pairs'], 4);
      // Each group holds one pilot of each team, so two feasible pairs
      // met and two did not.
      expect(fairness['unmet_opponent_count'], 2);
      expect(fairness['matchup_histogram'], {'0': 2, '1': 2});
    });
  });
}
