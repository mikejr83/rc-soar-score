import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'contests_table.dart';
import 'migrate.dart';

part 'database.g.dart';

/// SQLite database for local/offline contest data.
///
/// Opens a file-backed or in-memory SQLite database via `package:drift`'s
/// native `dart:ffi` executor and runs the versioned schema migrations.
@DriftDatabase(tables: [Contests])
class ContestDatabase extends _$ContestDatabase {
  /// Opens the database file at [path], creating parent directories if
  /// needed, and runs any pending schema migrations.
  ContestDatabase.open(String path)
    : super(
        NativeDatabase(File(path), enableMigrations: true),
      );

  /// Opens an in-memory database running the initial schema migration.
  ///
  /// Used by unit tests and other tooling that must not write to disk.
  ContestDatabase.inMemory()
    : super(NativeDatabase.memory());

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
