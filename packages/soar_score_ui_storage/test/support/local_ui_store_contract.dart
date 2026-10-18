import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';
import 'package:test/test.dart';

final intKey = LocalUiKey<int>(
  name: 'count',
  defaultValue: 0,
  encode: (value) => value,
  decode: (data) => data as int,
);

final listKey = LocalUiKey<List<String>>(
  name: 'names',
  defaultValue: const [],
  encode: (value) => value,
  decode: (data) => (data as List).cast<String>(),
);

/// The tests every [LocalUiBackend] must pass, run through a
/// [BackendLocalUiStore] so the whole stack is covered.
///
/// [open] gives a backend over empty storage when [fresh] is true, and over
/// the storage the previous call used when it is false (a reopened store).
void localUiStoreContract(
  String name, {
  required Future<LocalUiBackend> Function({required bool fresh}) open,
}) {
  group('$name local UI store', () {
    late LocalUiBackend backend;
    late BackendLocalUiStore store;

    setUp(() async {
      backend = await open(fresh: true);
      store = BackendLocalUiStore(backend);
    });
    tearDown(() => store.close());

    test('reads the default when nothing is stored', () async {
      expect(await store.get('a', intKey), 0);
    });

    test('reads back what was set, including structured values', () async {
      expect(await store.set('a', intKey, 7), isTrue);
      expect(await store.set('a', listKey, ['x', 'y']), isTrue);
      expect(await store.get('a', intKey), 7);
      expect(await store.get('a', listKey), ['x', 'y']);
    });

    test('a later set replaces the earlier value', () async {
      await store.set('a', intKey, 1);
      await store.set('a', intKey, 2);
      expect(await store.get('a', intKey), 2);
    });

    test('remove brings the default back', () async {
      await store.set('a', intKey, 5);
      expect(await store.remove('a', intKey), isTrue);
      expect(await store.get('a', intKey), 0);
      expect(await store.remove('a', intKey), isTrue);
    });

    test('a value written by one account is not visible to another', () async {
      await store.set('a', intKey, 5);
      expect(await store.get('b', intKey), 0);
      await store.set('b', intKey, 9);
      await store.remove('a', intKey);
      expect(await store.get('b', intKey), 9);
    });

    test('account ids with separators do not collide', () async {
      await store.set('a/b', intKey, 1);
      expect(await store.get('a', intKey), 0);
      expect(await store.get('a/b', intKey), 1);
    });

    test('a value of another key version reads as the default', () async {
      await store.set('a', intKey, 5);
      final newer = LocalUiKey<int>(
        name: intKey.name,
        version: 2,
        defaultValue: -1,
        encode: intKey.encode,
        decode: intKey.decode,
      );
      expect(await store.get('a', newer), -1);
      expect(await store.get('a', intKey), 5);
    });

    test('an unreadable value reads as the default', () async {
      await backend.write(BackendLocalUiStore.storageKey('a', 'count'), '{{');
      expect(await store.get('a', intKey), 0);
      await backend.write(
        BackendLocalUiStore.storageKey('a', 'count'),
        '{"v":1,"value":"not a number"}',
      );
      expect(await store.get('a', intKey), 0);
    });

    test('values survive reopening the backend', () async {
      await store.set('a', intKey, 3);
      await store.close();
      backend = await open(fresh: false);
      store = BackendLocalUiStore(backend);
      expect(await store.get('a', intKey), 3);
    });

    test('watch gives the current value, then each change', () async {
      await store.set('a', intKey, 1);
      final seen = <int>[];
      final subscription = store.watch('a', intKey).listen(seen.add);
      await pumpEventQueue();
      await store.set('a', intKey, 2);
      await store.set('b', intKey, 99);
      await store.remove('a', intKey);
      await pumpEventQueue();
      await subscription.cancel();
      expect(seen, [1, 2, 0]);
    });
  });
}
