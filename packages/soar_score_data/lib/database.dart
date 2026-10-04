import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/postgres_config.dart';

import 'contests_table.dart';
import 'migrate.dart';
import 'schema/database_profile.dart';
import 'schema/enum_values.dart';
import 'schema/table_groups.dart';

part 'database.g.dart';

/// Contests database.
///
/// Opens a file-backed or in-memory SQLite database via `package:drift`'s
/// native `dart:ffi` executor and runs the versioned schema migrations. The
/// [profile] decides which table groups are created.
@DriftDatabase(tables: [Contests])
class SoarScoreDatabase extends _$SoarScoreDatabase {
  /// Opens the database against [executor], creating the groups of [profile].
  SoarScoreDatabase(QueryExecutor executor, {required this.profile})
    : super(executor);

  final DatabaseProfile profile;

  /// The tables this database creates.
  List<TableInfo<Table, Object?>> get profileTables =>
      tablesFor(profile, allTables);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => migrateToVersion1(m, profileTables),
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
  return SoarScoreDatabase(executor, profile: DatabaseProfile.native);
}

SoarScoreDatabase createInMemoryDatabase() {
  final executor = NativeDatabase.memory();
  return SoarScoreDatabase(executor, profile: DatabaseProfile.native);
}

SoarScoreDatabase createPostgresDatabase(PostgresConfig config) {
  return SoarScoreDatabase(
    config.toPgDatabase(),
    profile: DatabaseProfile.server,
  );
}
