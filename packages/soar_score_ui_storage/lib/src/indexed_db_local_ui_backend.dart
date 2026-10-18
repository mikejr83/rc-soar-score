import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

import 'local_ui_backend.dart';

/// Web storage: one object store in an IndexedDB database of the browser.
class IndexedDbLocalUiBackend implements LocalUiBackend {
  IndexedDbLocalUiBackend._(this._db);

  static const String _store = 'ui_state';

  /// Opens (creating if needed) the database called [databaseName].
  static Future<IndexedDbLocalUiBackend> open({
    String databaseName = 'soar_score_ui',
  }) async {
    final opening = window.indexedDB.open(databaseName, 1);
    opening.onupgradeneeded = ((Event _) {
      final db = opening.result as IDBDatabase;
      if (!db.objectStoreNames.contains(_store)) {
        db.createObjectStore(_store);
      }
    }).toJS;
    final db = await _complete<JSAny?>(opening);
    return IndexedDbLocalUiBackend._(db as IDBDatabase);
  }

  final IDBDatabase _db;

  static Future<T> _complete<T extends JSAny?>(IDBRequest request) {
    final completer = Completer<T>();
    request.onsuccess = ((Event _) => completer.complete(
      request.result as T,
    )).toJS;
    request.onerror = ((Event _) => completer.completeError(
      StateError('IndexedDB request failed: ${request.error?.message}'),
    )).toJS;
    return completer.future;
  }

  IDBObjectStore _objectStore(String mode) =>
      _db.transaction(_store.toJS, mode).objectStore(_store);

  @override
  Future<String?> read(String storageKey) async {
    final result = await _complete<JSAny?>(
      _objectStore('readonly').get(storageKey.toJS),
    );
    return (result as JSString?)?.toDart;
  }

  @override
  Future<void> write(String storageKey, String value) =>
      _commit((store) => store.put(value.toJS, storageKey.toJS));

  @override
  Future<void> delete(String storageKey) =>
      _commit((store) => store.delete(storageKey.toJS));

  /// Runs a write and completes when its transaction has committed. A request
  /// succeeding is not enough: the transaction can still abort afterwards,
  /// for example when the storage quota is exceeded.
  Future<void> _commit(IDBRequest Function(IDBObjectStore store) write) {
    final transaction = _db.transaction(_store.toJS, 'readwrite');
    final completer = Completer<void>();
    transaction.oncomplete = ((Event _) => completer.complete()).toJS;
    void fail(String how) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('IndexedDB write $how: ${transaction.error?.message}'),
        );
      }
    }

    transaction.onabort = ((Event _) => fail('aborted')).toJS;
    transaction.onerror = ((Event _) => fail('failed')).toJS;
    write(transaction.objectStore(_store));
    return completer.future;
  }

  @override
  Future<void> close() async => _db.close();
}
