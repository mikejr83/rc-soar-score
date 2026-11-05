/// Strings kept by key in the browser. Kept thin so a native app can swap in
/// its own storage later. Every method may throw when storage is blocked.
abstract interface class KeyValueStore {
  String? read(String key);

  void write(String key, String value);

  void remove(String key);
}

/// Holds values for the life of the page. Used in tests and where the browser
/// has no storage.
class MemoryKeyValueStore implements KeyValueStore {
  final _values = <String, String>{};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;

  @override
  void remove(String key) => _values.remove(key);
}
