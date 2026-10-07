import 'dart:math' as math;

import 'package:soar_score_core/services/services.dart';

import 'package:test/test.dart';

void main() {
  final table = AcceptanceTable.instance;

  test('a move that does not raise the cost is always accepted', () {
    expect(table.probability(0, 256), 65536);
    expect(table.probability(-5, 256), 65536);
  });

  test('follows exp(-delta / T) in 65,536ths', () {
    // T = 1.0 is 256 in 256ths.
    for (final (delta, temperature) in [
      (1, 256),
      (2, 256),
      (1, 512),
      (3, 1024),
    ]) {
      final expected = 65536 * math.exp(-delta * 256 / temperature);
      expect(
        table.probability(delta, temperature),
        closeTo(expected, 8),
        reason: 'delta $delta at T=${temperature / 256}',
      );
    }
  });

  test('is strictly lower the worse the move', () {
    var last = table.probability(0, 256);
    for (var delta = 1; delta < 8; delta++) {
      final now = table.probability(delta, 256);
      expect(now, lessThan(last));
      last = now;
    }
  });

  test('a hopeless move has no chance', () {
    expect(table.probability(100, 256), 0);
    expect(table.probability(1, 1), 0);
  });

  test('the table is built from whole numbers and stays small', () {
    expect(table.length, inInclusiveRange(100, 200));
  });
}
