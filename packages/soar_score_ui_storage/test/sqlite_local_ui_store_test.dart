@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:soar_score_ui_storage/src/sqlite_local_ui_backend.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';
import 'package:test/test.dart';

import 'support/local_ui_store_contract.dart';

void main() {
  late Directory directory;
  setUp(() => directory = Directory.systemTemp.createTempSync('ui_store'));
  tearDown(() => directory.deleteSync(recursive: true));

  // The contract reopens by path, so the same file backs a reopened store.
  var counter = 0;
  late String path;
  localUiStoreContract(
    'SQLite',
    open: ({required fresh}) async {
      if (fresh) path = p.join(directory.path, 'ui${counter++}.db');
      return SqliteLocalUiBackend.open(path);
    },
  );

  test('the table is its own, not a contest entity table', () async {
    final backend = SqliteLocalUiBackend.inMemory();
    await BackendLocalUiStore(backend).set('a', intKey, 1);
    expect(
      await backend.read(BackendLocalUiStore.storageKey('a', 'count')),
      isNotNull,
    );
  });

  test(
    'openLocalUiStore falls back to memory when the file cannot open',
    () async {
      final blocked = File(p.join(directory.path, 'file'))
        ..writeAsStringSync('');
      final store = await openLocalUiStore(directory: blocked.path);
      expect(await store.set('a', intKey, 4), isTrue);
      expect(await store.get('a', intKey), 4);
    },
  );

  test('openLocalUiStore opens soar_score_ui.db in the directory', () async {
    final store = await openLocalUiStore(directory: directory.path);
    await store.set('a', intKey, 4);
    await store.close();
    expect(
      File(p.join(directory.path, 'soar_score_ui.db')).existsSync(),
      isTrue,
    );
  });
}
