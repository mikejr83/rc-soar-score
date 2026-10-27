import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

DrawSpec _spec({
  int pilots = 12,
  int rounds = 4,
  int groups = 3,
  int seedCount = 3,
  int attempts = 3,
}) => DrawSpec(
  pilots: [for (var i = 1; i <= pilots; i++) DrawPilot(_id(i))],
  rounds: rounds,
  groupsPerRound: groups,
  teamProtection: false,
  laneMode: LaneMode.random,
  seed: 11,
  seedCount: seedCount,
  attemptsPerRound: attempts,
);

List<List<List<(Id, int?)>>> _slots(DrawResult result) => [
  for (final round in result.rounds)
    [
      for (final group in round)
        [for (final slot in group) (slot.pilot.participationId, slot.lane)],
    ],
];

void main() {
  group('IsolateDrawRunner', () {
    test('draws exactly what drawing in process draws', () async {
      final spec = _spec();

      final isolated = await const IsolateDrawRunner().run(spec);
      final local = spec.generate();

      expect(_slots(isolated), _slots(local));
      expect(isolated.seed, local.seed);
      expect(isolated.fairness, local.fairness);
    });

    test('reports progress from the isolate', () async {
      final seen = <int>[];

      await const IsolateDrawRunner().run(
        _spec(),
        onProgress: (progress) => seen.add(progress.percent),
      );

      expect(seen, isNotEmpty);
      expect(seen, [...seen]..sort());
      expect(seen.last, lessThan(100));
    });

    test('hands back settings it cannot meet as an ArgumentError', () {
      expect(
        const IsolateDrawRunner().run(_spec(groups: 20)),
        throwsArgumentError,
      );
    });

    test('stops a long draw when it is cancelled', () async {
      final cancellation = DrawCancellation();
      final started = DateTime.now();

      final run = const IsolateDrawRunner().run(
        _spec(pilots: 60, rounds: 14, groups: 6, seedCount: 20, attempts: 50),
        onProgress: (_) => cancellation.cancel(),
        cancellation: cancellation,
      );

      await expectLater(run, throwsA(isA<DrawCancelledError>()));
      expect(
        DateTime.now().difference(started),
        lessThan(const Duration(seconds: 20)),
      );
    });

    test('does not start a draw that is already cancelled', () {
      final cancellation = DrawCancellation()..cancel();

      expect(
        const IsolateDrawRunner().run(_spec(), cancellation: cancellation),
        throwsA(isA<DrawCancelledError>()),
      );
    });
  });
}
