import 'dart:async';

import 'package:soar_score_core/services/sync/keyed_lock.dart';
import 'package:test/test.dart';

void main() {
  test('bodies with one key run one after another', () async {
    final lock = KeyedLock();
    final log = <String>[];
    final gate = Completer<void>();

    final first = lock.run('a', () async {
      log.add('first start');
      await gate.future;
      log.add('first end');
    });
    final second = lock.run('a', () async => log.add('second'));
    await Future<void>.delayed(Duration.zero);
    expect(log, ['first start']);

    gate.complete();
    await Future.wait([first, second]);

    expect(log, ['first start', 'first end', 'second']);
  });

  test('different keys do not wait for each other', () async {
    final lock = KeyedLock();
    final gate = Completer<void>();
    final blocked = lock.run('a', () => gate.future);

    final other = await lock.run('b', () async => 'done');

    expect(other, 'done');
    gate.complete();
    await blocked;
  });

  test('a failing body releases the key', () async {
    final lock = KeyedLock();

    await expectLater(
      lock.run('a', () async => throw StateError('boom')),
      throwsStateError,
    );

    expect(await lock.run('a', () async => 1), 1);
  });
}
