import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

/// Pilots 1 to 4: A, B, C and D.
final _pilots = [for (var i = 1; i <= 4; i++) DrawPilot(_id(i))];

DrawSlot _slot(int n) => DrawSlot(_pilots[n - 1], null);

/// One round in which A and B fly together and so do C and D.
List<List<DrawSlot>> _abCd() => [
  [_slot(1), _slot(2)],
  [_slot(3), _slot(4)],
];

bool _together(List<List<DrawSlot>> round, int a, int b) => round.any(
  (group) =>
      group.any((s) => s.pilot.participationId == _id(a)) &&
      group.any((s) => s.pilot.participationId == _id(b)),
);

void main() {
  group('a draw that continues earlier rounds', () {
    test('the basic draw keeps pilots apart who already met often', () {
      final history = [_abCd(), _abCd(), _abCd()];

      final round = const BasicDraw()
          .generate(
            pilots: _pilots,
            rounds: 1,
            groupsPerRound: 2,
            teamProtection: false,
            laneMode: LaneMode.none,
            random: SeededRandom(3),
            attemptsPerRound: 20,
            history: history,
          )
          .single;

      expect(_together(round, 1, 2), isFalse);
      expect(_together(round, 3, 4), isFalse);
    });

    test('the optimizer pulls apart pilots who already met often', () {
      final history = [_abCd(), _abCd(), _abCd()];

      final round = const DrawOptimizer()
          .improve(
            pilots: _pilots,
            start: [_abCd()],
            teamProtection: false,
            laneMode: LaneMode.none,
            random: SeededRandom(3),
            history: history,
          )
          .single;

      expect(_together(round, 1, 2), isFalse);
      expect(_together(round, 3, 4), isFalse);
    });

    test('without history the optimizer leaves a balanced draw alone', () {
      final round = const DrawOptimizer()
          .improve(
            pilots: _pilots,
            start: [_abCd()],
            teamProtection: false,
            laneMode: LaneMode.none,
            random: SeededRandom(3),
          )
          .single;

      // One round has no better arrangement: any split meets two pairs.
      expect([for (final g in round) g.length], everyElement(2));
    });

    test('the engine meets everyone once across history and new rounds', () {
      final result = const DrawEngine().generate(
        pilots: _pilots,
        rounds: 2,
        groupsPerRound: 2,
        teamProtection: false,
        laneMode: LaneMode.none,
        seed: 11,
        history: [_abCd()],
        attemptsPerRound: 10,
        iterationsPerPlacement: 100,
      );

      expect(result.rounds, hasLength(2));
      expect(result.fairness['unmet_opponent_count'], 0);
      expect(result.fairness['max_duplicate_matchups'], 1);
      expect(result.fairness['feasible_pairs'], 6);
    });

    test('the same seed and history give the same draw', () {
      List<List<List<Id>>> run() => [
        for (final round
            in const DrawEngine()
                .generate(
                  pilots: _pilots,
                  rounds: 2,
                  groupsPerRound: 2,
                  teamProtection: false,
                  laneMode: LaneMode.none,
                  seed: 11,
                  history: [_abCd()],
                  attemptsPerRound: 10,
                  iterationsPerPlacement: 100,
                )
                .rounds)
          [
            for (final group in round)
              [for (final slot in group) slot.pilot.participationId],
          ],
      ];

      expect(run(), run());
    });

    test('pilots who left are ignored but their meetings still count', () {
      final retired = DrawPilot(_id(9));
      final history = [
        [
          [_slot(1), DrawSlot(retired, null)],
          [_slot(2), _slot(3), _slot(4)],
        ],
      ];

      final result = const DrawEngine().generate(
        pilots: _pilots,
        rounds: 1,
        groupsPerRound: 2,
        teamProtection: false,
        laneMode: LaneMode.none,
        seed: 2,
        history: history,
        attemptsPerRound: 5,
        iterationsPerPlacement: 50,
      );

      final flown = {
        for (final group in result.rounds.single)
          for (final slot in group) slot.pilot.participationId,
      };
      expect(flown, {_id(1), _id(2), _id(3), _id(4)});
    });
  });
}
