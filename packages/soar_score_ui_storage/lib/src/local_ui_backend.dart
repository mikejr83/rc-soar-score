/// Raw string storage under a [LocalUiStore]: one text value per storage key.
///
/// Implementations may throw; the store catches and logs. Each platform has
/// its own (memory for tests, SQLite on native, IndexedDB on web) and all
/// pass the same contract tests.
abstract class LocalUiBackend {
  /// The text stored under [storageKey], or `null` when none.
  Future<String?> read(String storageKey);

  /// Stores [value] under [storageKey], replacing any earlier one.
  Future<void> write(String storageKey, String value);

  /// Removes [storageKey]; does nothing when it is absent.
  Future<void> delete(String storageKey);

  Future<void> close();
}
