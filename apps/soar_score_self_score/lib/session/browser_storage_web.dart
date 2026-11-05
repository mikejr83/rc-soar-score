import 'package:web/web.dart' as web;

import 'key_value_store.dart';

class _LocalStorage implements KeyValueStore {
  @override
  String? read(String key) => web.window.localStorage.getItem(key);

  @override
  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  @override
  void remove(String key) => web.window.localStorage.removeItem(key);
}

/// The browser's local storage.
KeyValueStore openBrowserStorage() => _LocalStorage();
