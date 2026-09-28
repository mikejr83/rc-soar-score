import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/postgres_config.dart';

import 'contests_table.dart';
import 'migrate.dart';

part 'database.g.dart';

/// Contests database.
///
/// Opens a file-backed or in-memory SQLite database via `package:drift`'s
/// native `dart:ffi` executor and runs the versioned schema migrations.
@DriftDatabase(tables: [Contests])
class SoarScoreDatabase extends _$SoarScoreDatabase {
  /// Opens the database against [executor].
  SoarScoreDatabase(QueryExecutor executor) : super(executor);

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

SoarScoreDatabase createLocalDatabase(File dbFilePath) {
  final executor = NativeDatabase(dbFilePath, enableMigrations: true);
  return SoarScoreDatabase(executor);
}

SoarScoreDatabase createInMemoryDatabase() {
  final executor = NativeDatabase.memory();
  return SoarScoreDatabase(executor);
}

SoarScoreDatabase createPostgresDatabase(PostgresConfig config) {
  return SoarScoreDatabase(config.toPgDatabase());
}
