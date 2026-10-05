import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('applyFinalRounding', () {
    test('rounds half away from zero', () {
      expect(applyFinalRounding(2.5, RoundingMode.round, 0), 3);
      expect(applyFinalRounding(2.45, RoundingMode.round, 1), 2.5);
      expect(applyFinalRounding(-2.5, RoundingMode.round, 0), -3);
    });

    test('absorbs binary floating-point error', () {
      expect(applyFinalRounding(2.675, RoundingMode.round, 2), 2.68);
      expect(applyFinalRounding(1.005, RoundingMode.round, 2), 1.01);
    });

    test('truncates instead of rounding', () {
      expect(applyFinalRounding(2.99, RoundingMode.truncate, 1), 2.9);
      expect(applyFinalRounding(2.99, RoundingMode.truncate, 0), 2);
    });

    test('truncation absorbs float error just below a boundary', () {
      expect(applyFinalRounding(2.9999999999, RoundingMode.truncate, 0), 3);
      expect(applyFinalRounding(0.3 * 3, RoundingMode.truncate, 1), 0.9);
    });

    test('supports zero to three decimal places', () {
      expect(applyFinalRounding(1.23456, RoundingMode.round, 3), 1.235);
      expect(applyFinalRounding(1.23456, RoundingMode.truncate, 3), 1.234);
    });

    test('leaves zero alone', () {
      expect(applyFinalRounding(0, RoundingMode.round, 1), 0);
    });
  });
}
