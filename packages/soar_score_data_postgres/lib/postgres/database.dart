import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';

import 'connection_info.dart';
import 'contests_table.dart';
import 'migrate.dart';

part 'database.g.dart';

/// PostgreSQL database for the deployed API's persistent contest storage.
///
/// Opens a connection via `drift_postgres`'s [PgDatabase] executor, which
/// drives the Postgres SQL dialect, and runs the versioned schema migrations
/// on first use. The schema is maintained independently from
/// `soar_score_data_sqlite`'s (see the decision recorded in ticket 016).
@DriftDatabase(tables: [Contests])
class SoarScoreDatabase extends _$ContestDatabase {
  /// Opens a connection against [config] and runs any pending schema
  /// migrations on first use.
  SoarScoreDatabase.open(PostgresConfig config)
    : super(
        PgDatabase(
          endpoint: config.toEndpoint(),
          settings: config.toSettings(),
          logStatements: true,
        ),
      );

  /// Current schema version; bump this when the schema changes and add a
  /// migration step for the new version.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: migrateToVersion1,
    onUpgrade: (m, from, to) {
      throw UnsupportedError(
        'Schema upgrade from $from to $to is not implemented yet: '
        'only schema version 1 exists (see migrate.dart).',
      );
    },
  );
}
