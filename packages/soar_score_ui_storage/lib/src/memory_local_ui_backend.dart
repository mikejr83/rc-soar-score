import 'local_ui_backend.dart';

/// Keeps values in memory only; for tests and as the fallback when the real
/// storage cannot be opened.
class MemoryLocalUiBackend implements LocalUiBackend {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String storageKey) async => _values[storageKey];

  @override
  Future<void> write(String storageKey, String value) async {
    _values[storageKey] = value;
  }

  @override
  Future<void> delete(String storageKey) async {
    _values.remove(storageKey);
  }

  @override
  Future<void> close() async {}
}
