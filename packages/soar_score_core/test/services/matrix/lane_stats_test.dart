import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

/// One group per round; [lanes] gives the lane of pilots 1 and 2 each round.
List<List<List<DrawSlot>>> _rounds(List<(int, int)> lanes) => [
  for (final (a, b) in lanes)
    [
      [DrawSlot(DrawPilot(_id(1)), a), DrawSlot(DrawPilot(_id(2)), b)],
    ],
];

void main() {
  test('is null when the draw has no lanes', () {
    final rounds = [
      [
        [DrawSlot(DrawPilot(_id(1)), null)],
      ],
    ];

    expect(LaneStats.of(rounds), isNull);
  });

  test('a pilot who flies every lane equally costs nothing', () {
    // Two lanes, four rounds: each pilot flies each lane twice.
    final stats = LaneStats.of(_rounds([(1, 2), (2, 1), (1, 2), (2, 1)]))!;

    expect(stats.laneCount, 2);
    expect(stats.target, 2);
    expect(stats.cost, 0);
    expect(stats.idealCost, 0);
    expect(stats.uniformityIndex, 0);
  });

  test('flying one lane every time costs the squared deviations', () {
    // Pilot 1 always lane 1, pilot 2 always lane 2: counts 4,0 and 0,4 and
    // a target of 2, so each of the four entries is 2 away.
    final stats = LaneStats.of(_rounds([(1, 2), (1, 2), (1, 2), (1, 2)]))!;

    expect(stats.cost, 16);
    expect(stats.uniformityIndex, closeTo(2, 1e-12));
  });

  test('an odd number of rounds cannot be perfectly even', () {
    // Two lanes, three rounds: target 1.5; the best is 2 and 1 per pilot,
    // so 0.25 * 2 per pilot = 0.5, for two pilots 1.0.
    final stats = LaneStats.of(_rounds([(1, 2), (2, 1), (1, 2)]))!;

    expect(stats.idealCost, closeTo(1, 1e-12));
    expect(stats.cost, closeTo(1, 1e-12));
  });
}
