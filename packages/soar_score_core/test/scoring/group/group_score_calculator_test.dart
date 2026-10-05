import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

List<double> _scores(List<PilotRound> pilots, GroupScoreOptions options) => [
  for (final e in calculateGroupScores(pilots, options)) e.groupScore,
];

GroupScoreOptions _options(
  GroupScoreMode mode, {
  RoundingMode rounding = RoundingMode.round,
  int decimals = 1,
}) => GroupScoreOptions(
  mode: mode,
  roundingMode: rounding,
  decimalPlaces: decimals,
);

void main() {
  group('Raw mode', () {
    test('uses the raw score', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 500, landingBonus: 50),
        PilotRound(pilotId: 'b', flightPoints: 400.26),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.raw)), [550, 400.3]);
    });
  });

  group('Normalized mode', () {
    test('gives the best pilot 1000 and scales the others', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 500, landingBonus: 50),
        PilotRound(pilotId: 'b', flightPoints: 275),
        PilotRound(pilotId: 'c', flightPoints: 0),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.normalized)), [
        1000,
        500,
        0,
      ]);
    });

    test('pilots with the same raw score get the same score', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 300),
        PilotRound(pilotId: 'b', flightPoints: 200, landingBonus: 100),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.normalized)), [
        1000,
        1000,
      ]);
    });

    test('an all-zero group scores zero without dividing by zero', () {
      final pilots = [
        PilotRound(pilotId: 'a'),
        PilotRound(pilotId: 'b', flightPoints: 10, deductions: 50),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.normalized)), [0, 0]);
    });

    test('retired pilots do not set the best score', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 300),
        PilotRound(pilotId: 'r', flightPoints: 900, retired: true),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.normalized)), [1000, 0]);
    });

    test('a group of only retired pilots scores zero', () {
      final pilots = [PilotRound(pilotId: 'r', flightPoints: 9, retired: true)];

      expect(_scores(pilots, _options(GroupScoreMode.normalized)), [0]);
    });

    test('rounds once, at the end', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 3),
        PilotRound(pilotId: 'b', flightPoints: 1),
      ];

      expect(
        _scores(pilots, _options(GroupScoreMode.normalized, decimals: 2)),
        [1000, 333.33],
      );
      expect(
        _scores(
          pilots,
          _options(
            GroupScoreMode.normalized,
            rounding: RoundingMode.truncate,
            decimals: 0,
          ),
        ),
        [1000, 333],
      );
    });

    test('does not round the raw score before normalizing', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 100.4),
        PilotRound(pilotId: 'b', flightPoints: 100.3),
      ];

      expect(
        _scores(pilots, _options(GroupScoreMode.normalized, decimals: 3)),
        [1000, 999.004],
      );
    });
  });

  group('Time mode', () {
    test('normalizes flight time first, then adds the landing bonus', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 600, landingBonus: 10),
        PilotRound(pilotId: 'b', flightPoints: 300, landingBonus: 90),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.time)), [1010, 590]);
    });

    test('the best raw score need not have the best time', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 400, landingBonus: 100),
        PilotRound(pilotId: 'b', flightPoints: 450, landingBonus: 0),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.time)), [988.9, 1000]);
    });

    test('an all-zero time keeps the landing bonus', () {
      final pilots = [PilotRound(pilotId: 'a', landingBonus: 25)];

      expect(_scores(pilots, _options(GroupScoreMode.time)), [25]);
    });

    test('retired pilots do not set the best time and score zero', () {
      final pilots = [
        PilotRound(pilotId: 'a', flightPoints: 100),
        PilotRound(
          pilotId: 'r',
          flightPoints: 900,
          landingBonus: 50,
          retired: true,
        ),
      ];

      expect(_scores(pilots, _options(GroupScoreMode.time)), [1000, 0]);
    });
  });

  group('entries', () {
    test('keep pilot order and report the unrounded raw score', () {
      final entries = calculateGroupScores([
        PilotRound(pilotId: 'a', flightPoints: 1.234),
        PilotRound(pilotId: 'b', flightPoints: 2.468),
      ], _options(GroupScoreMode.raw, decimals: 1));

      expect(entries.map((e) => e.pilotId), ['a', 'b']);
      expect(entries.first.rawScore, 1.234);
      expect(entries.first.groupScore, 1.2);
    });

    test('an empty group has no entries', () {
      expect(
        calculateGroupScores([], _options(GroupScoreMode.normalized)),
        isEmpty,
      );
    });

    test('a pilot listed twice is rejected', () {
      expect(
        () => calculateGroupScores([
          PilotRound(pilotId: 'a'),
          PilotRound(pilotId: 'a'),
        ], _options(GroupScoreMode.raw)),
        throwsA(isA<ScoringValidationError>()),
      );
    });
  });

  group('GroupScoreOptions', () {
    test('defaults to Normalized, Round, one decimal', () {
      final options = GroupScoreOptions();

      expect(options.mode, GroupScoreMode.normalized);
      expect(options.roundingMode, RoundingMode.round);
      expect(options.decimalPlaces, 1);
    });

    test('rejects decimal places outside 0 to 3', () {
      expect(() => GroupScoreOptions(decimalPlaces: 4), throwsArgumentError);
      expect(() => GroupScoreOptions(decimalPlaces: -1), throwsArgumentError);
    });
  });
}
