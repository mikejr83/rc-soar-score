import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('PilotRound', () {
    test('raw score adds the landing bonus', () {
      final round = PilotRound(
        pilotId: 'a',
        flightPoints: 500,
        landingBonus: 50,
      );

      expect(round.rawScore, 550);
      expect(round.timeScore, 500);
    });

    test('deductions come off the score', () {
      final round = PilotRound(
        pilotId: 'a',
        flightPoints: 500,
        landingBonus: 50,
        deductions: 30,
      );

      expect(round.rawScore, 520);
      expect(round.timeScore, 470);
    });

    test('scores never go below zero', () {
      final round = PilotRound(
        pilotId: 'a',
        flightPoints: 10,
        landingBonus: 20,
        deductions: 100,
      );

      expect(round.rawScore, 0);
      expect(round.timeScore, 0);
    });

    test('rejects negative inputs', () {
      expect(
        () => PilotRound(pilotId: 'a', flightPoints: -1),
        throwsArgumentError,
      );
      expect(
        () => PilotRound(pilotId: 'a', landingBonus: -1),
        throwsArgumentError,
      );
      expect(
        () => PilotRound(pilotId: 'a', deductions: -1),
        throwsArgumentError,
      );
    });
  });
}
