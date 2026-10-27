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
  bool allowBackToBack = false,
  int seed = 5,
  List<List<List<DrawSlot>>> history = const [],
}) => const DrawEngine().generate(
  pilots: pilots,
  rounds: rounds,
  groupsPerRound: groups,
  teamProtection: teamProtection,
  laneMode: LaneMode.none,
  allowBackToBack: allowBackToBack,
  seed: seed,
  seedCount: 2,
  attemptsPerRound: 5,
  iterationsPerPlacement: 60,
  history: history,
);

Set<Id> _ids(List<DrawSlot> group) => {
  for (final slot in group) slot.pilot.participationId,
};

/// The pilots who fly in the last group of a round and the first of the next.
Set<Id> _backToBack(List<List<List<DrawSlot>>> rounds) => {
  for (var r = 0; r + 1 < rounds.length; r++)
    ..._ids(rounds[r].last).intersection(_ids(rounds[r + 1].first)),
};

void main() {
  group('back-to-back flights', () {
    test('are never drawn when not allowed, across seeds and sizes', () {
      for (final (count, groups) in [(12, 3), (13, 3), (10, 4), (7, 2)]) {
        for (var seed = 1; seed <= 8; seed++) {
          final result = _draw(_pilots(count), groups: groups, seed: seed);

          expect(
            _backToBack(result.rounds),
            isEmpty,
            reason: '$count pilots, $groups groups, seed $seed',
          );
        }
      }
    });

    test('are never drawn with team protection either', () {
      for (var seed = 1; seed <= 5; seed++) {
        final result = _draw(
          _pilots(12, teams: 4),
          teamProtection: true,
          seed: seed,
        );

        expect(_backToBack(result.rounds), isEmpty, reason: 'seed $seed');
      }
    });

    test('happen in some draws when allowed (the option has an effect)', () {
      final any = [
        for (var seed = 1; seed <= 8; seed++)
          _backToBack(
            _draw(_pilots(12), allowBackToBack: true, seed: seed).rounds,
          ),
      ].any((found) => found.isNotEmpty);

      expect(any, isTrue);
    });

    test('the draw is the same as before when allowed', () {
      final pilots = _pilots(12);

      final withOption = _draw(pilots, allowBackToBack: true);
      final without = const DrawEngine().generate(
        pilots: pilots,
        rounds: 6,
        groupsPerRound: 3,
        teamProtection: false,
        laneMode: LaneMode.none,
        seed: 5,
        seedCount: 2,
        attemptsPerRound: 5,
        iterationsPerPlacement: 60,
      );

      expect(withOption.fairness, without.fairness);
    });

    test('a continued draw respects the last kept round', () {
      final pilots = _pilots(12);
      final kept = _draw(pilots, rounds: 2).rounds;

      for (var seed = 1; seed <= 6; seed++) {
        final more = _draw(pilots, rounds: 3, seed: seed, history: kept);

        expect(_backToBack([...kept, ...more.rounds]), isEmpty);
      }
    });

    test('a single group cannot avoid them and names the constraint', () {
      expect(
        () => _draw(_pilots(6), groups: 1, rounds: 2),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('back-to-back'),
          ),
        ),
      );
    });

    test('a last group too big to leave a first group names it too', () {
      // 3 groups of 2, 2 and 2 pilots from 6: round 2 group 1 needs 2 pilots
      // outside the 2 of the last group, which is possible; with 2 groups and
      // a 3 pilot last group the first group needs 3 of the other 3.
      final pilots = _pilots(5);
      final kept = [
        [
          [DrawSlot(pilots[0], null)],
          [for (final p in pilots.skip(1)) DrawSlot(p, null)],
        ],
      ];

      expect(
        () => _draw(pilots, groups: 2, rounds: 1, history: kept),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('back-to-back'),
          ),
        ),
      );
    });
  });
}
