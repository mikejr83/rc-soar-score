import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('without drops', () {
    test('sums the round scores', () {
      final t = total(pilot([1000, 800.5, 950.2]), asOf: 3);

      expect(t.rawTotal, 2750.7);
      expect(t.overallScore, 2750.7);
      expect(t.droppedRounds, isEmpty);
      expect(t.skippedDrops, 0);
      expect(t.isPreliminary, isFalse);
    });

    test('only counts rounds up to the as-of round', () {
      final t = total(pilot([1000, 800, 950]), asOf: 2);

      expect(t.rawTotal, 1800);
    });

    test('has no drops while fewer than the drop round are complete', () {
      final t = total(pilot([1000, 800, 950]), asOf: 3, dropAfter: [4]);

      expect(t.droppedRounds, isEmpty);
      expect(t.skippedDrops, 0);
    });

    test('sums without floating-point drift', () {
      final t = total(pilot([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]), asOf: 7);

      expect(t.rawTotal, 2.8);
    });
  });

  group('dropped rounds', () {
    final scores = <double>[900, 400, 950, 700, 1000];

    test('drops the lowest round once the drop round is complete', () {
      final t = total(pilot(scores), asOf: 5, dropAfter: [4]);

      expect(t.droppedRounds, [2]);
      expect(t.rawTotal, 3950);
      expect(t.overallScore, 3550);
    });

    test('drops a second round after the second drop round', () {
      final p = pilot([...scores, 650, 980, 300, 990]);

      expect(total(p, asOf: 7, dropAfter: [4, 8]).droppedRounds, [2]);
      expect(total(p, asOf: 8, dropAfter: [4, 8]).droppedRounds, [2, 8]);
      expect(total(p, asOf: 9, dropAfter: [4, 8]).droppedRounds, [2, 8]);
    });

    test('drops the earliest of equal lowest rounds', () {
      final t = total(pilot([500, 300, 300, 900]), asOf: 4, dropAfter: [4]);

      expect(t.droppedRounds, [2]);
    });

    test('drops a zero as the lowest round', () {
      final t = total(pilot([0, 300, 500, 900]), asOf: 4, dropAfter: [4]);

      expect(t.droppedRounds, [1]);
      expect(t.overallScore, 1700);
    });
  });

  group('non-droppable zeros', () {
    test('are never dropped; the next lowest round is', () {
      final t = total(
        pilot([0, 300, 500, 900], nonDroppable: {1}),
        asOf: 4,
        dropAfter: [4],
      );

      expect(t.droppedRounds, [2]);
      expect(t.overallScore, 1400);
      expect(t.skippedDrops, 0);
    });

    test('skip the drop when every round is a non-droppable zero', () {
      final t = total(
        pilot([0, 0, 0, 0], nonDroppable: {1, 2, 3, 4}),
        asOf: 4,
        dropAfter: [4],
      );

      expect(t.droppedRounds, isEmpty);
      expect(t.skippedDrops, 1);
      expect(t.overallScore, 0);
    });

    test('a second drop is skipped when only non-droppable zeros remain', () {
      final t = total(
        pilot([0, 0, 800], nonDroppable: {1, 2}),
        asOf: 3,
        dropAfter: [1, 3],
      );

      expect(t.droppedRounds, [3]);
      expect(t.skippedDrops, 1);
    });

    test('a droppable zero in the same pilot is still dropped', () {
      final t = total(
        pilot([0, 0, 400, 600], nonDroppable: {1}),
        asOf: 4,
        dropAfter: [4],
      );

      expect(t.droppedRounds, [2]);
    });
  });

  group('cumulative penalties', () {
    test('come off after the drops', () {
      final t = total(
        pilot([900, 400, 950, 700], penalties: {1: 50, 3: 25}),
        asOf: 4,
        dropAfter: [4],
      );

      expect(t.penaltyTotal, 75);
      expect(t.overallScore, 900 + 950 + 700 - 75);
    });

    test('are not removed when their round is dropped', () {
      final t = total(
        pilot([900, 400, 950, 700], penalties: {2: 100}),
        asOf: 4,
        dropAfter: [4],
      );

      expect(t.droppedRounds, [2]);
      expect(t.penaltyTotal, 100);
      expect(t.overallScore, 900 + 950 + 700 - 100);
    });

    test('do not change which round is dropped', () {
      final t = total(
        pilot([900, 450, 950, 700], penalties: {1: 600}),
        asOf: 4,
        dropAfter: [4],
      );

      expect(t.droppedRounds, [2]);
    });

    test('an absent penalty counts as zero', () {
      expect(total(pilot([100]), asOf: 1).penaltyTotal, 0);
    });
  });

  group('missing, retired and preliminary', () {
    test('a round with no score is a zero and makes the total preliminary', () {
      final t = total(pilot([900, 800]), asOf: 3);

      expect(t.rawTotal, 1700);
      expect(t.isPreliminary, isTrue);
    });

    test('a missing round is a zero that a drop can remove', () {
      final t = total(pilot([900, 800, 700]), asOf: 4, dropAfter: [4]);

      expect(t.droppedRounds, [4]);
      expect(t.overallScore, 2400);
      expect(t.isPreliminary, isTrue);
    });

    test('rounds from the retirement round on are zeros, not preliminary', () {
      final t = total(pilot([900, 800], retiredAtRound: 3), asOf: 5);

      expect(t.rawTotal, 1700);
      expect(t.isPreliminary, isFalse);
    });

    test('a missing round before the retirement round is preliminary', () {
      final p = PilotRounds(
        pilotId: 'a',
        scores: [RoundScore(round: 1, groupScore: 900)],
        retiredAtRound: 3,
      );

      expect(total(p, asOf: 4).isPreliminary, isTrue);
    });

    test('an open review makes the total preliminary', () {
      final t = total(pilot([900, 800], underReview: {2}), asOf: 2);

      expect(t.isPreliminary, isTrue);
    });

    test('before any round there is nothing to total', () {
      final t = total(pilot([]), asOf: 0);

      expect(t.overallScore, 0);
      expect(t.isPreliminary, isFalse);
    });
  });

  group('invalid input', () {
    test('rejects a score with more than three decimals', () {
      expect(
        () => total(pilot([1.2345]), asOf: 1),
        throwsA(isA<ScoringValidationError>()),
      );
    });

    test('rejects negative scores, penalties and rounds', () {
      expect(() => RoundScore(round: 1, groupScore: -1), throwsArgumentError);
      expect(
        () => RoundScore(round: 1, groupScore: 1, cumulativePenalty: -1),
        throwsArgumentError,
      );
      expect(() => RoundScore(round: 0, groupScore: 1), throwsArgumentError);
    });

    test('rejects a round that appears twice', () {
      expect(
        () => PilotRounds(
          pilotId: 'a',
          scores: [
            RoundScore(round: 1, groupScore: 1),
            RoundScore(round: 1, groupScore: 2),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid drop rounds', () {
      for (final bad in [
        [0],
        [4, 4],
        [8, 4],
        [1, 2, 3],
      ]) {
        expect(
          () => ContestTotalOptions(dropAfterRounds: bad),
          throwsArgumentError,
          reason: '$bad',
        );
      }
    });
  });

  group('with F5J flights', () {
    test(
      'a restart zero under Non-Droppable 0 is kept; a lower score drops',
      () {
        final f5j = F5jProfile();
        final restart = f5j.calculate(
          {'motor_restart': true},
          overrides: {'motor_restart_mode': 'non_droppable'},
        );
        final low = f5j.calculate({'time_flown': 100, 'launch_height': 100});

        final p = PilotRounds(
          pilotId: 'a',
          scores: [
            RoundScore(
              round: 1,
              groupScore: 0,
              nonDroppable: restart.nonDroppable,
            ),
            RoundScore(round: 2, groupScore: low.rawScore),
            RoundScore(round: 3, groupScore: 600),
          ],
        );

        final t = total(p, asOf: 3, dropAfter: [3]);
        expect(t.droppedRounds, [2]);
        expect(t.overallScore, 600);
      },
    );
  });
}
