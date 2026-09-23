/// Soar Score SQLite data access layer.
///
/// SQLite persistence for local/offline contest data, built on `drift` and
/// the native `sqlite3` FFI bindings (no Flutter dependency). Consumers
/// should import only `package:soar_score_data_sqlite/soar_score_data_sqlite.dart`.
library;

export 'repositories/contest_repository.dart';
export 'sqlite/contests_table.dart';
export 'sqlite/database.dart';
export 'sqlite/migrate.dart';
