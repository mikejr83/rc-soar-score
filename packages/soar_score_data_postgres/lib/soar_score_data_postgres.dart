/// Soar Score PostgreSQL data access layer.
///
/// Server-side persistent contest storage for the deployed API, built on
/// `drift` and `drift_postgres` (no Flutter dependency). Run only inside
/// `soar_score_server`; it accepts and reconciles data synced up from
/// offline `soar_score_data_sqlite` clients (sync logic itself is later
/// work). Consumers should import only
/// `package:soar_score_data_postgres/soar_score_data_postgres.dart`.
library;

export 'postgres/connection_info.dart';
export 'postgres/contests_table.dart';
export 'postgres/database.dart';
export 'postgres/migrate.dart';
export 'repositories/contest_repository.dart';
