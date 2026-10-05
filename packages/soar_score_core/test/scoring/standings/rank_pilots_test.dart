import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('rankPilots without the tie-breaker', () {
    test('orders by overall score, highest first', () {
      final ranking = rankPilots([
        pilotTotal('b', 2900),
        pilotTotal('a', 3500),
        pilotTotal('c', 3100.5),
      ]);

      expect(ranking.places.map((p) => p.pilotId), ['a', 'c', 'b']);
      expect(placesOf(ranking), {
        'a': [1, false],
        'c': [2, false],
        'b': [3, false],
      });
    });

    test('equal scores share a place and the next place is skipped', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000),
        pilotTotal('b', 3000),
        pilotTotal('c', 2000),
      ]);

      expect(placesOf(ranking), {
        'a': [1, true],
        'b': [1, true],
        'c': [3, false],
      });
    });

    test('keeps the given order for tied pilots', () {
      final ranking = rankPilots([
        pilotTotal('z', 1000),
        pilotTotal('a', 1000),
      ]);

      expect(ranking.places.map((p) => p.pilotId), ['z', 'a']);
    });

    test('ignores the tie-breaker values', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000, dropped: 900),
        pilotTotal('b', 3000, dropped: 100),
      ]);

      expect(placesOf(ranking), {
        'a': [1, true],
        'b': [1, true],
      });
    });

    test('is preliminary when any total is', () {
      expect(
        rankPilots([pilotTotal('a', 1), pilotTotal('b', 2, preliminary: true)])
            .isPreliminary,
        isTrue,
      );
      expect(rankPilots([pilotTotal('a', 1)]).isPreliminary, isFalse);
    });

    test('an empty contest has no places', () {
      expect(rankPilots([]).places, isEmpty);
    });

    test('rejects a pilot listed twice', () {
      expect(
        () => rankPilots([pilotTotal('a', 1), pilotTotal('a', 2)]),
        throwsA(isA<ScoringValidationError>()),
      );
    });
  });

  group('rankPilots with the tie-breaker', () {
    test('a higher dropped-round score wins first', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000, dropped: 400, rawPoints: 5000),
        pilotTotal('b', 3000, dropped: 600, rawPoints: 4000),
      ], tieBreakerEnabled: true);

      expect(placesOf(ranking), {
        'b': [1, false],
        'a': [2, false],
      });
    });

    test('equal dropped scores fall back to total raw flight points', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000, dropped: 500, rawPoints: 4000.5),
        pilotTotal('b', 3000, dropped: 500, rawPoints: 4100),
      ], tieBreakerEnabled: true);

      expect(placesOf(ranking), {
        'b': [1, false],
        'a': [2, false],
      });
    });

    test('pilots level on every key stay tied', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000, dropped: 500, rawPoints: 4000),
        pilotTotal('b', 3000, dropped: 500, rawPoints: 4000),
        pilotTotal('c', 2500),
      ], tieBreakerEnabled: true);

      expect(placesOf(ranking), {
        'a': [1, true],
        'b': [1, true],
        'c': [3, false],
      });
    });

    test('does not reorder pilots with different overall scores', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000, dropped: 0),
        pilotTotal('b', 3001, dropped: 0),
      ], tieBreakerEnabled: true);

      expect(ranking.places.map((p) => p.pilotId), ['b', 'a']);
    });

    test('splits a three-way tie in steps', () {
      final ranking = rankPilots([
        pilotTotal('a', 3000, dropped: 500, rawPoints: 4000),
        pilotTotal('b', 3000, dropped: 500, rawPoints: 4000),
        pilotTotal('c', 3000, dropped: 300, rawPoints: 9000),
      ], tieBreakerEnabled: true);

      expect(placesOf(ranking), {
        'a': [1, true],
        'b': [1, true],
        'c': [3, false],
      });
    });
  });

  group('with contest totals', () {
    test('ranks pilots from their calculated totals', () {
      final options = ContestTotalOptions(dropAfterRounds: [3]);
      ContestTotal totalFor(String id, List<double> scores) =>
          calculateContestTotal(
            PilotRounds(
              pilotId: id,
              scores: [
                for (var i = 0; i < scores.length; i++)
                  RoundScore(
                    round: i + 1,
                    groupScore: scores[i],
                    rawScore: scores[i],
                  ),
              ],
            ),
            asOfRound: 3,
            options: options,
          );

      final ranking = rankPilots([
        totalFor('a', [1000, 800, 600]),
        totalFor('b', [900, 850, 700]),
      ]);

      // a keeps 1000 + 800; b keeps 900 + 850.
      expect(placesOf(ranking), {
        'a': [1, false],
        'b': [2, false],
      });
    });
  });
}
