import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Id _id(int n) =>
    Id.parse('019c0000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}');

final _contest = _id(500);

DrawSpec _spec({int seedCount = 3}) => DrawSpec(
  pilots: [for (var i = 1; i <= 12; i++) DrawPilot(_id(i))],
  rounds: 4,
  groupsPerRound: 3,
  teamProtection: false,
  laneMode: LaneMode.none,
  seed: 11,
  seedCount: seedCount,
  attemptsPerRound: 3,
);

List<List<List<Id>>> _ids(DrawResult result) => [
  for (final round in result.rounds)
    [
      for (final group in round)
        [for (final slot in group) slot.pilot.participationId],
    ],
];

/// A runner that waits until [release] completes, so a test can look at a
/// draw that is still running.
class _HeldRunner implements DrawRunner {
  final release = Completer<void>();

  @override
  Future<DrawResult> run(
    DrawSpec spec, {
    void Function(DrawProgress progress)? onProgress,
    DrawCancellation? cancellation,
  }) async {
    final cancelled = Completer<void>();
    cancellation?.onCancel(cancelled.complete);
    await Future.any([release.future, cancelled.future]);
    if (cancellation?.isCancelled ?? false) throw DrawCancelledError();
    onProgress?.call(const DrawProgress(percent: 40, seed: 2, seedCount: 3));
    return spec.generate();
  }
}

void main() {
  group('DrawEngine progress', () {
    test('reports rising percentages below 100 and never changes the draw', () {
      final seen = <DrawProgress>[];
      final watched = _spec().generate(onProgress: seen.add);
      final silent = _spec().generate();

      expect(_ids(watched), _ids(silent));
      expect(watched.seed, silent.seed);
      expect(seen, isNotEmpty);
      expect(seen.first.percent, 0);
      expect(seen.every((p) => p.percent >= 0 && p.percent < 100), isTrue);
      final percents = [for (final p in seen) p.percent];
      expect(percents, [...percents]..sort());
      expect({for (final p in seen) p.seed}, {1, 2, 3});
      expect(seen.every((p) => p.seedCount == 3), isTrue);
    });
  });

  group('InProcessDrawRunner', () {
    test('gives the same draw as drawing directly', () async {
      final ran = await const InProcessDrawRunner().run(_spec());

      expect(_ids(ran), _ids(_spec().generate()));
    });

    test('refuses a draw already cancelled', () {
      final cancellation = DrawCancellation()..cancel();

      expect(
        const InProcessDrawRunner().run(_spec(), cancellation: cancellation),
        throwsA(isA<DrawCancelledError>()),
      );
    });
  });

  group('DrawJobs', () {
    test('knows a draw while it runs and after it completes', () async {
      final jobs = DrawJobs();
      final runner = _HeldRunner();
      final id = _id(1);

      final result = jobs.run(_contest, id, runner, _spec());
      expect(jobs.status(_contest, id)?.state, DrawJobState.running);
      runner.release.complete();
      await result;

      expect(jobs.status(_contest, id)?.state, DrawJobState.completed);
      expect(jobs.status(_contest, id)?.progress.percent, 40);
      expect(jobs.status(_contest, _id(2)), isNull);
    });

    test(
      'cancelling a running draw fails it with DrawCancelledError',
      () async {
        final jobs = DrawJobs();
        final runner = _HeldRunner();
        final id = _id(1);

        final result = jobs.run(_contest, id, runner, _spec());
        final expectation = expectLater(
          result,
          throwsA(isA<DrawCancelledError>()),
        );
        expect(jobs.cancel(_contest, id)?.state, DrawJobState.running);
        await expectation;

        expect(jobs.status(_contest, id)?.state, DrawJobState.cancelled);
      },
    );

    test('cancelling a finished or unknown draw changes nothing', () async {
      final jobs = DrawJobs();
      final id = _id(1);
      await jobs.run(
        _contest,
        id,
        const InProcessDrawRunner(),
        _spec(seedCount: 1),
      );

      expect(jobs.cancel(_contest, id)?.state, DrawJobState.completed);
      expect(jobs.cancel(_contest, _id(9)), isNull);
    });

    test('does not know a draw through another contest', () async {
      final jobs = DrawJobs();
      final id = _id(1);
      await jobs.run(
        _contest,
        id,
        const InProcessDrawRunner(),
        _spec(seedCount: 1),
      );

      expect(jobs.status(_id(501), id), isNull);
      expect(jobs.cancel(_id(501), id), isNull);
      expect(jobs.status(_contest, id)?.state, DrawJobState.completed);
    });

    test('refuses to start a draw that is already running', () async {
      final jobs = DrawJobs();
      final runner = _HeldRunner();
      final id = _id(1);

      final first = jobs.run(_contest, id, runner, _spec());
      await expectLater(
        jobs.run(_contest, id, runner, _spec()),
        throwsA(
          isA<ContestStateError>().having(
            (e) => e.code,
            'code',
            'draw_running',
          ),
        ),
      );
      runner.release.complete();
      await first;
    });

    test('remembers only the latest finished draws', () async {
      final jobs = DrawJobs(keep: 2);
      for (var i = 1; i <= 4; i++) {
        await jobs.run(
          _contest,
          _id(i),
          const InProcessDrawRunner(),
          _spec(seedCount: 1),
        );
      }

      expect(jobs.status(_contest, _id(1)), isNull);
      expect(jobs.status(_contest, _id(2)), isNull);
      expect(jobs.status(_contest, _id(3)), isNotNull);
      expect(jobs.status(_contest, _id(4)), isNotNull);
    });
  });
}
