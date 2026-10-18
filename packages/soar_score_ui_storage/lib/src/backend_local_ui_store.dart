import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'local_ui_backend.dart';
import 'local_ui_key.dart';
import 'local_ui_store.dart';

final _logger = Logger('LocalUiStore');

/// A [LocalUiStore] over any [LocalUiBackend].
///
/// Values are stored as `{"v": <key version>, "value": <encoded>}` under
/// `<account id>/<key name>`. Changes made through this instance reach its
/// [watch] streams; changes made by another instance or browser tab do not.
class BackendLocalUiStore implements LocalUiStore {
  BackendLocalUiStore(this._backend);

  final LocalUiBackend _backend;
  final Set<StreamController<Object?>> _watchers = {};
  final StreamController<_Change> _changes = StreamController.broadcast(
    sync: true,
  );

  static String storageKey(String accountId, String name) =>
      '${Uri.encodeComponent(accountId)}/$name';

  @override
  Future<T> get<T>(String accountId, LocalUiKey<T> key) async {
    final storageKey = BackendLocalUiStore.storageKey(accountId, key.name);
    try {
      final raw = await _backend.read(storageKey);
      if (raw == null) {
        return key.defaultValue;
      }
      final value = _decode(storageKey, raw, key);
      return value;
    } catch (error, stackTrace) {
      _logger.warning('Cannot read $storageKey', error, stackTrace);
      return key.defaultValue;
    }
  }

  T _decode<T>(String storageKey, String raw, LocalUiKey<T> key) {
    try {
      final envelope = jsonDecode(raw);
      if (envelope is! Map || envelope['v'] != key.version) {
        _logger.info('Ignoring $storageKey: stored under another version');
        return key.defaultValue;
      }
      return key.decode(envelope['value']);
    } catch (error) {
      _logger.warning('Ignoring unreadable $storageKey: $error');
      return key.defaultValue;
    }
  }

  @override
  Future<bool> set<T>(String accountId, LocalUiKey<T> key, T value) async {
    final storageKey = BackendLocalUiStore.storageKey(accountId, key.name);
    try {
      final raw = jsonEncode({'v': key.version, 'value': key.encode(value)});
      await _backend.write(storageKey, raw);
    } catch (error, stackTrace) {
      _logger.warning('Cannot write $storageKey', error, stackTrace);
      return false;
    }
    _changes.add(_Change(storageKey, value));
    return true;
  }

  @override
  Future<bool> remove<T>(String accountId, LocalUiKey<T> key) async {
    final storageKey = BackendLocalUiStore.storageKey(accountId, key.name);
    try {
      await _backend.delete(storageKey);
    } catch (error, stackTrace) {
      _logger.warning('Cannot remove $storageKey', error, stackTrace);
      return false;
    }
    _changes.add(_Change(storageKey, key.defaultValue));
    return true;
  }

  @override
  Stream<T> watch<T>(String accountId, LocalUiKey<T> key) {
    final storageKey = BackendLocalUiStore.storageKey(accountId, key.name);
    late final StreamController<T> controller;
    StreamSubscription<_Change>? subscription;
    controller = StreamController<T>(
      onListen: () {
        var changed = false;
        subscription = _changes.stream
            .where((change) => change.storageKey == storageKey)
            .listen((change) {
              changed = true;
              controller.add(change.value as T);
            });
        // A change that lands before the first read finishes is newer.
        get(accountId, key).then((value) {
          if (!changed && !controller.isClosed) {
            controller.add(value);
          }
        });
      },
      onCancel: () {
        _watchers.remove(controller);
        return subscription?.cancel();
      },
    );
    _watchers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> close() async {
    await _changes.close();
    // Live watchers end instead of waiting for a change that cannot come.
    for (final watcher in _watchers.toList()) {
      await watcher.close();
    }
    _watchers.clear();
    try {
      await _backend.close();
    } catch (error, stackTrace) {
      _logger.warning('Cannot close the backend', error, stackTrace);
    }
  }
}

class _Change {
  const _Change(this.storageKey, this.value);

  final String storageKey;
  final Object? value;
}
