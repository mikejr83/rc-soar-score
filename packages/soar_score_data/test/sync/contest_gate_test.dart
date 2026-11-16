import 'dart:async';

import 'package:postgres/postgres.dart' show ServerException;
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

  test('a wait past the lock timeout is a ContestBusyError, and the '
      'waiter keeps nothing', () async {
    final release = Completer<void>();
    final firstIn = Completer<void>();
    final holder = withContestScoreGate(first.db, _contestId, () async {
      firstIn.complete();
      await release.future;
    });
    await firstIn.future;

    var ran = false;
    await expectLater(
      withContestScoreGate(second.db, _contestId, () async {
        ran = true;
      }, lockTimeout: '200ms'),
      throwsA(isA<core.ContestBusyError>()),
    );
    expect(ran, isFalse);

    release.complete();
    await holder;
    // The gate is free again, and the loser's connection is usable.
    await withContestScoreGate(second.db, _contestId, () async {});
  });

  test('a deadlock between two contests\' gates is a ContestBusyError for '
      'one of them', () async {
    final firstHolds = Completer<void>();
    final secondHolds = Completer<void>();
    // Open both before they compete: a first use races on the schema table.
    await second.db.customSelect('SELECT 1').get();
    await first.db.customStatement(
      'CREATE TABLE IF NOT EXISTS gate_probe (id integer PRIMARY KEY)',
    );

    Future<Object?> crossing(
      Installation inst,
      String mine,
      String theirs,
      Completer<void> iHold,
      Completer<void> theyHold,
    ) => withContestScoreGate(inst.db, mine, () async {
      await inst.db.customStatement(
        'INSERT INTO gate_probe VALUES (${mine.hashCode})',
      );
      iHold.complete();
      await theyHold.future;
      await withContestScoreGate(inst.db, theirs, () async {});
    }).then<Object?>((_) => null, onError: (Object e) => e);

    final outcomes = await Future.wait([
      crossing(first, 'deadlock-a', 'deadlock-b', firstHolds, secondHolds),
      crossing(second, 'deadlock-b', 'deadlock-a', secondHolds, firstHolds),
    ]);

    expect(outcomes.whereType<core.ContestBusyError>(), hasLength(1));
    expect(outcomes.where((o) => o == null), hasLength(1));
    expect(
      await first.db.customSelect('SELECT id FROM gate_probe').get(),
      hasLength(1),
      reason: 'only the winner kept its row; the loser rolled back whole',
    );
  });

  test('another database error is not a ContestBusyError', () async {
    await expectLater(
      withContestScoreGate(first.db, _contestId, () async {
        await first.db.customSelect('SELECT 1 / 0 AS boom').get();
      }),
      throwsA(
        allOf(isNot(isA<core.ContestBusyError>()), isA<ServerException>()),
      ),
    );
  });

  test('a row-lock timeout inside the gate is a ContestBusyError', () async {
    await first.db.customStatement(
      'CREATE TABLE gate_probe (id integer PRIMARY KEY)',
    );
    await first.db.customStatement('INSERT INTO gate_probe VALUES (1)');
    final release = Completer<void>();
    final locked = Completer<void>();
    final holder = first.db.transaction(() async {
      await first.db.customSelect('SELECT id FROM gate_probe FOR UPDATE').get();
      locked.complete();
      await release.future;
    });
    await locked.future;

    await expectLater(
      withContestScoreGate(second.db, _contestId, () async {
        await second.db
            .customSelect('SELECT id FROM gate_probe FOR UPDATE')
            .get();
      }, lockTimeout: '200ms'),
      throwsA(isA<core.ContestBusyError>()),
    );

    release.complete();
    await holder;
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
