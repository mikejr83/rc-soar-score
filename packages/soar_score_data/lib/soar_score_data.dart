/// Unified Soar Score data access layer.
///
/// Single package supporting both PostgreSQL (server) and SQLite (embedded)
/// via Drift's QueryExecutor abstraction. Consumers choose the executor when
/// constructing `RcSoarScoreDatabase`.
library;

export 'contests_table.dart';
export 'database.dart';
export 'migrate.dart';
export 'postgres_config.dart';
export 'repositories/repository.dart';
export 'repositories/contest_repository.dart';
