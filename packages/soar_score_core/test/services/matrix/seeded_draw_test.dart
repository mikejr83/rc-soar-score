import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

List<DrawPilot> _pilots(int count) => [
  for (var i = 1; i <= count; i++) DrawPilot(_id(i)),
];

/// Pilot n is in place n.
Map<Id, int> _places(int count) => {for (var i = 1; i <= count; i++) _id(i): i};

List<List<int>> _numbers(List<List<DrawSlot>> groups) => [
  for (final group in groups)
    [
      for (final slot in group)
        int.parse(slot.pilot.participationId.value.split('-').last, radix: 16),
    ]..sort(),
];

void main() {
  group('SeededDraw', () {
    test('puts the leaders in the last group and the tail in group 1', () {
      final groups = const SeededDraw().generate(
        pilots: _pilots(9),
        places: _places(9),
        groupsPerRound: 3,
        laneMode: LaneMode.none,
        random: SeededRandom(1),
      );

      expect(_numbers(groups), [
        [7, 8, 9],
        [4, 5, 6],
        [1, 2, 3],
      ]);
    });

    test('the lowest groups take the extra pilots', () {
      final groups = const SeededDraw().generate(
        pilots: _pilots(11),
        places: _places(11),
        groupsPerRound: 3,
        laneMode: LaneMode.none,
        random: SeededRandom(1),
      );

      // 11 pilots in 3 groups: groups 1 and 2 hold 4, the leaders' group 3.
      expect(_numbers(groups), [
        [8, 9, 10, 11],
        [4, 5, 6, 7],
        [1, 2, 3],
      ]);
    });

    test('orders by place, not by the order pilots were given', () {
      final pilots = _pilots(4);
      final groups = const SeededDraw().generate(
        pilots: pilots.reversed.toList(),
        places: _places(4),
        groupsPerRound: 2,
        laneMode: LaneMode.none,
        random: SeededRandom(1),
      );

      expect(_numbers(groups), [
        [3, 4],
        [1, 2],
      ]);
    });

    test('pilots without a standing rank below every pilot with one', () {
      final groups = const SeededDraw().generate(
        pilots: _pilots(4),
        places: {_id(1): 1, _id(2): 2},
        groupsPerRound: 2,
        laneMode: LaneMode.none,
        random: SeededRandom(1),
      );

      expect(_numbers(groups), [
        [3, 4],
        [1, 2],
      ]);
    });

    test('tied pilots are ordered by the seed, the same every time', () {
      List<List<int>> draw(int seed) => _numbers(
        const SeededDraw().generate(
          pilots: _pilots(4),
          places: {_id(1): 1, _id(2): 2, _id(3): 2, _id(4): 4},
          groupsPerRound: 4,
          laneMode: LaneMode.none,
          random: SeededRandom(seed),
        ),
      );

      expect(draw(5), draw(5));
      expect(draw(5).first, [4]);
      expect(draw(5).last, [1]);
      expect(
        {for (var seed = 0; seed < 20; seed++) draw(seed)[2].single},
        {2, 3},
      );
    });

    test('gives every pilot of a group a lane with random lanes', () {
      final groups = const SeededDraw().generate(
        pilots: _pilots(8),
        places: _places(8),
        groupsPerRound: 2,
        laneMode: LaneMode.random,
        random: SeededRandom(1),
      );

      for (final group in groups) {
        expect([for (final slot in group) slot.lane]..sort(), [1, 2, 3, 4]);
      }
    });

    test('refuses a group count the pilots cannot fill', () {
      for (final groups in [0, 5]) {
        expect(
          () => const SeededDraw().generate(
            pilots: _pilots(4),
            places: _places(4),
            groupsPerRound: groups,
            laneMode: LaneMode.none,
            random: SeededRandom(1),
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('DrawEngine.generateSeeded', () {
    test('draws one round after the history and reports its fairness', () {
      final pilots = _pilots(6);
      final first = const BasicDraw().generate(
        pilots: pilots,
        rounds: 1,
        groupsPerRound: 2,
        teamProtection: false,
        laneMode: LaneMode.none,
        random: SeededRandom(2),
      );

      final result = const DrawEngine().generateSeeded(
        pilots: pilots,
        places: _places(6),
        groupsPerRound: 2,
        laneMode: LaneMode.none,
        seed: 9,
        history: first,
      );

      expect(result.rounds, hasLength(1));
      expect(_numbers(result.rounds.single), [
        [4, 5, 6],
        [1, 2, 3],
      ]);
      expect(result.seed, 9);
      expect(result.fairness['feasible_pairs'], 15);
      expect(result.fairness['fairness_score'], isA<double>());
    });
  });
}
