import 'dart:async';

import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';
import 'package:test/test.dart';

import 'support/local_ui_store_contract.dart';

class _BrokenBackend implements LocalUiBackend {
  @override
  Future<String?> read(String storageKey) => throw StateError('no read');

  @override
  Future<void> write(String storageKey, String value) =>
      throw StateError('no write');

  @override
  Future<void> delete(String storageKey) => throw StateError('no delete');

  @override
  Future<void> close() => throw StateError('no close');
}

void main() {
  test('failures fall back to defaults instead of throwing', () async {
    final store = BackendLocalUiStore(_BrokenBackend());
    expect(await store.get('a', intKey), 0);
    expect(await store.set('a', intKey, 1), isFalse);
    expect(await store.remove('a', intKey), isFalse);
    await store.close();
  });

  test(
    'a value the key cannot encode is not saved and does not throw',
    () async {
      final key = LocalUiKey<int>(
        name: 'bad',
        defaultValue: 0,
        encode: (value) => throw ArgumentError('no'),
        decode: (data) => data as int,
      );
      final store = BackendLocalUiStore(MemoryLocalUiBackend());
      expect(await store.set('a', key, 1), isFalse);
    },
  );

  test('a failed write is not announced to watchers', () async {
    final store = BackendLocalUiStore(_BrokenBackend());
    final seen = <int>[];
    final subscription = store.watch('a', intKey).listen(seen.add);
    await pumpEventQueue();
    await store.set('a', intKey, 3);
    await pumpEventQueue();
    await subscription.cancel();
    expect(seen, [0]);
  });

  test('closing the store ends live watch streams', () async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final done = Completer<void>();
    final subscription = store
        .watch('a', intKey)
        .listen((_) {}, onDone: done.complete);
    await pumpEventQueue();
    await store.close();
    await done.future.timeout(const Duration(seconds: 1));
    await subscription.cancel();
  });
}
