import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// The schema version stored in the local SQLite file at [file] (Drift keeps
/// it in `PRAGMA user_version`), read without opening the file through the
/// database or changing it.
///
/// Returns `null` when the file is missing, empty, or not a database this app
/// can read, so a caller treats it as "no database yet". Used before the
/// database opens, to tell a first run from an upgrade.
int? readLocalSchemaVersion(File file) {
  if (!file.existsSync() || file.lengthSync() == 0) return null;
  Database? db;
  try {
    db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    final version = db.select('PRAGMA user_version').first.values.first;
    return version is int && version > 0 ? version : null;
  } on Object {
    return null;
  } finally {
    db?.close();
  }
}
