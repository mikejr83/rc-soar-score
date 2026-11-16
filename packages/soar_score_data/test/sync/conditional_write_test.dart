import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() {
  forEachBackend(_tests);
  forPostgresOnly(_twoConnections);
}

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  test('a save from an old revision is refused and stores nothing', () async {
    final first = await inst.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata(requestId: 'a')),
    );
    final second = await inst.unitOfWork.run(
      (c) => c.save(
        contest(name: 'Second', id: first.id, revision: first.revision),
        metadata: metadata(requestId: 'b'),
      ),
    );

    await expectLater(
      inst.unitOfWork.run(
        (c) => c.save(
          contest(name: 'Late', id: first.id, revision: first.revision),
          metadata: metadata(requestId: 'c'),
        ),
      ),
      throwsA(isA<core.StaleRevisionError>()),
    );
    final stored = await inst.stores.of('Contest').findJson(first.id);
    expect(stored!['name'], 'Second');
    expect(stored['revision'], second.revision);
  });

  test('a new row is refused when one already exists at its id', () async {
    final first = await inst.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata(requestId: 'a')),
    );
    final store = inst.stores.of('Contest');
    final json = store.encode(contest(name: 'Rival', id: first.id));

    expect(await store.upsertJsonIfRevision(json, null), isFalse);
    expect((await store.findJson(first.id))!['name'], first.name);
  });
}

/// Two connections: the writer that did not take the gate must not overwrite
/// a row another connection changed after it read it.
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

  test('a writer waiting on a changed row finds it stale', () async {
    final saved = await first.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata(requestId: 'a')),
    );
    final events = <String>[];
    final release = Completer<void>();
    final held = Completer<void>();

    final holder = first.db.transaction(() async {
      await first.unitOfWork.run(
        (c) => c.save(
          contest(name: 'Holder', id: saved.id, revision: saved.revision),
          metadata: metadata(requestId: 'b'),
        ),
      );
      held.complete();
      await release.future;
      events.add('holder-commit');
    });
    await held.future;

    final waiter = second.unitOfWork
        .run(
          (c) => c.save(
            contest(name: 'Waiter', id: saved.id, revision: saved.revision),
            metadata: metadata(requestId: 'c'),
          ),
        )
        .then<Object>((r) => r, onError: (Object e) => e)
        .whenComplete(() => events.add('waiter-done'));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    release.complete();
    await holder;
    final outcome = await waiter;

    expect(events, ['holder-commit', 'waiter-done']);
    expect(outcome, isA<core.StaleRevisionError>());
    expect(
      (await first.stores.of('Contest').findJson(saved.id))!['name'],
      'Holder',
    );
  });

  test('FOR UPDATE keeps another connection\'s write waiting', () async {
    final saved = await first.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata(requestId: 'a')),
    );
    final events = <String>[];
    final release = Completer<void>();
    final held = Completer<void>();

    final holder = first.db.transaction(() async {
      final rows = await first.stores
          .of('Contest')
          .whereId('id', saved.id, forUpdate: true);
      expect(rows, hasLength(1));
      held.complete();
      await release.future;
      events.add('holder-commit');
    });
    await held.future;

    final waiter = second.unitOfWork
        .run(
          (c) => c.save(
            contest(name: 'Waiter', id: saved.id, revision: saved.revision),
            metadata: metadata(requestId: 'c'),
          ),
        )
        .whenComplete(() => events.add('waiter-done'));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    release.complete();
    await holder;
    await waiter;

    expect(events, ['holder-commit', 'waiter-done']);
  });

  test('a row deleted while a writer waits is not brought back', () async {
    final saved = await first.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata(requestId: 'a')),
    );
    final release = Completer<void>();
    final held = Completer<void>();

    final holder = first.db.transaction(() async {
      await first.stores.of('Contest').remove(saved.id);
      held.complete();
      await release.future;
    });
    await held.future;

    final waiter = second.unitOfWork
        .run(
          (c) => c.save(
            contest(name: 'Waiter', id: saved.id, revision: saved.revision),
            metadata: metadata(requestId: 'c'),
          ),
        )
        .then<Object>((r) => r, onError: (Object e) => e);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    release.complete();
    await holder;

    expect(await waiter, isA<core.StaleRevisionError>());
    expect(await first.stores.of('Contest').findJson(saved.id), isNull);
  });
}
