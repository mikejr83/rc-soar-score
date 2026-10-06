import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

/// The flight penalty entered with a score is generic: every discipline takes
/// it and deducts it from the raw score (`plan/data-model/contest-options.md`).
void main() {
  final f3j = F3jProfile();
  final ales = AlesProfile();
  final thermal = ThermalProfile();

  group('F3J', () {
    test('is deducted from the raw score and reported as a deduction', () {
      final result = f3j.calculate({
        'time_flown': 540.0,
        'flight_penalty': 100,
      }, landingBonus: 20);
      expect(result.flightPenalty, 100);
      expect(result.rawScore, 460);
      expect(result.toPilotRound('p1').deductions, 100);
    });

    test('defaults to zero and floors the raw score at zero', () {
      expect(f3j.calculate({'time_flown': 540.0}).flightPenalty, 0);
      final result = f3j.calculate({
        'time_flown': 100.0,
        'flight_penalty': 500,
      });
      expect(result.rawScore, 0);
    });
  });

  group('ALES', () {
    test('is deducted from the raw score and reported as a deduction', () {
      final result = ales.calculate(
        {'time_flown': 400, 'flight_penalty': 50},
        overrides: const {'target_time': 480},
        landingBonus: 30,
      );
      expect(result.flightPenalty, 50);
      expect(result.rawScore, 380);
      expect(result.toPilotRound('p1').deductions, 50);
    });

    test('floors the raw score at zero', () {
      final result = ales.calculate(
        {'time_flown': 10, 'flight_penalty': 500},
        overrides: const {'target_time': 480},
      );
      expect(result.rawScore, 0);
    });
  });

  group('Thermal', () {
    test('is deducted from the raw score and reported as a deduction', () {
      final result = thermal.calculate({
        'time_flown': 550,
        'flight_penalty': 25,
      }, landingBonus: 20);
      expect(result.flightPenalty, 25);
      expect(result.rawScore, 545);
      expect(result.toPilotRound('p1').deductions, 25);
    });

    test('floors the raw score at zero', () {
      final result = thermal.calculate({
        'time_flown': 10,
        'flight_penalty': 500,
      });
      expect(result.rawScore, 0);
    });
  });
}
