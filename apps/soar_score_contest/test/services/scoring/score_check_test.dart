import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/scoring/score_check.dart';

CheckInput _in(String key, Map<String, Object?> c, {bool entered = true}) =>
    CheckInput(
      rowKey: key,
      pilot: 'Pilot $key',
      components: c,
      entered: entered,
    );

void main() {
  test('a complete group is clean', () {
    final r = runScoreCheck([
      _in('1', {'time_flown': 540, 'launch_height': 180}),
      _in('2', {'time_flown': 480, 'launch_height': 150}),
    ]);
    expect(r.isClean, isTrue);
    expect(r.checked, 2);
  });

  test('reports a missing entry', () {
    final r = runScoreCheck([_in('1', const {}, entered: false)]);
    expect(r.findings.single.message, 'Nothing entered yet.');
  });

  test('reports a short time and a height out of range', () {
    final r = runScoreCheck([
      _in('1', {'time_flown': 90, 'launch_height': 300}),
    ]);
    expect(r.findings.map((f) => f.field), ['time_flown', 'launch_height']);
    expect(r.of('1'), hasLength(2));
  });

  test('a zeroed flight is not range checked', () {
    final r = runScoreCheck([
      _in('1', {'out_of_bounds': true}),
    ]);
    expect(r.isClean, isTrue);
  });
}
