import 'package:sqlite3/sqlite3.dart';

import 'local_ui_backend.dart';

/// Native storage: one `ui_state` table in its own SQLite file.
///
/// The file is separate from the contest database on purpose, so resetting or
/// replacing contest data never touches UI state, and no contest entity table
/// holds any.
class SqliteLocalUiBackend implements LocalUiBackend {
  SqliteLocalUiBackend._(this._db) {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ui_state (
        storage_key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Opens (creating if needed) the database file at [path].
  factory SqliteLocalUiBackend.open(String path) =>
      SqliteLocalUiBackend._(sqlite3.open(path));

  /// A database that lives only as long as the backend.
  factory SqliteLocalUiBackend.inMemory() =>
      SqliteLocalUiBackend._(sqlite3.openInMemory());

  final Database _db;

  @override
  Future<String?> read(String storageKey) async {
    final rows = _db.select(
      'SELECT value FROM ui_state WHERE storage_key = ?',
      [storageKey],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> write(String storageKey, String value) async {
    _db.execute(
      'INSERT INTO ui_state (storage_key, value, updated_at) VALUES (?, ?, ?) '
      'ON CONFLICT(storage_key) DO UPDATE SET '
      'value = excluded.value, updated_at = excluded.updated_at',
      [storageKey, value, DateTime.now().toUtc().toIso8601String()],
    );
  }

  @override
  Future<void> delete(String storageKey) async {
    _db.execute('DELETE FROM ui_state WHERE storage_key = ?', [storageKey]);
  }

  @override
  Future<void> close() async => _db.close();
}
