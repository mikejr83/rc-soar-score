import 'package:drift/drift.dart';

/// Initial schema migration (schema version 1): creates [tables], the tables
/// of the database's profile.
Future<void> migrateToVersion1(
  Migrator migrator,
  Iterable<TableInfo<Table, Object?>> tables,
) async {
  for (final table in tables) {
    await migrator.createTable(table);
  }
}
