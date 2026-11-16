import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/sync/contest_gate.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() {
  forEachBackend(_tests);
  forPostgresOnly(_twoConnections);
}

const _contestId = 'contest-under-gate';

void _tests(Backend backend) {
  late Installation inst;
  late List<core.SyncScopeKey> heard;
  setUp(() async {
    inst = await Installation.open(backend);
    heard = [];
    inst.db.localChanges.listen(heard.add);
  });
  tearDown(() => inst.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('gated writers of one contest run one after another', () async {
    final events = <String>[];
    final release = Completer<void>();
    final firstIn = Completer<void>();

    final first = withContestScoreGate(inst.db, _contestId, () async {
      events.add('first-in');
      firstIn.complete();
      await release.future;
      events.add('first-out');
    });
    await firstIn.future;
    final second = withContestScoreGate(inst.db, _contestId, () async {
      events.add('second-in');
    });
    // Give a gate that does not exclude every chance to let the second in.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    release.complete();
    await Future.wait([first, second]);

    expect(events, ['first-in', 'first-out', 'second-in']);
  });

  test('announces after the gate commits, once', () async {
    late core.Contest saved;
    await withContestScoreGate(inst.db, _contestId, () async {
      saved = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata(requestId: 'a')),
      );
      await inst.unitOfWork.run(
        (c) => c.save(
          contest(name: 'Again', id: saved.id),
          metadata: metadata(requestId: 'b'),
        ),
      );
      await settle();
      expect(heard, isEmpty, reason: 'not committed yet');
    });
    await settle();

    expect(heard, [core.ContestScopeKey(saved.id)]);
  });

  test('announces nothing when the gate rolls back', () async {
    await expectLater(
      withContestScoreGate(inst.db, _contestId, () async {
        await inst.unitOfWork.run(
          (c) => c.save(contest(), metadata: metadata()),
        );
        throw StateError('abandon');
      }),
      throwsStateError,
    );
    await settle();

    expect(heard, isEmpty);
    expect(await inst.count('contests'), 0);
  });

  test('a failed unit of work inside the gate is not announced', () async {
    await withContestScoreGate(inst.db, _contestId, () async {
      await expectLater(
        inst.unitOfWork.run((c) async {
          await c.save(contest(), metadata: metadata());
          throw StateError('abandon');
        }),
        throwsStateError,
      );
    });
    await settle();

    expect(heard, isEmpty);
  });
}

/// Two connections, as two server instances: the second writer must wait for
/// the first, not merely queue behind it on a shared connection.
void _twoConnections(Backend backend) {
  late Installation first;
  late Installation second;
  setUp(() async {
    first = await Installation.open(backend);
    second = await first.reopen();
  });
  tearDown(() async {
    await second.db.close();
    await first.close();
  });

  test('a second connection waits for the first connection\'s gate', () async {
    final events = <String>[];
    final release = Completer<void>();
    final firstIn = Completer<void>();

    final holder = withContestScoreGate(first.db, _contestId, () async {
      events.add('first-in');
      firstIn.complete();
      await release.future;
      events.add('first-out');
    });
    await firstIn.future;
    final waiter = withContestScoreGate(second.db, _contestId, () async {
      events.add('second-in');
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    release.complete();
    await Future.wait([holder, waiter]);

    expect(events, ['first-in', 'first-out', 'second-in']);
  });

  test('gates of different contests do not wait for each other', () async {
    final release = Completer<void>();
    final firstIn = Completer<void>();
    final holder = withContestScoreGate(first.db, _contestId, () async {
      firstIn.complete();
      await release.future;
    });
    await firstIn.future;

    await withContestScoreGate(second.db, 'another-contest', () async {});
    release.complete();
    await holder;
  });
}
