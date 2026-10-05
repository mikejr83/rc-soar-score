import 'package:drift/drift.dart';

import 'schema/custom_indexes.dart';

/// Initial schema migration (schema version 1): creates [tables], the tables
/// of the database's profile, then the indexes a table cannot declare itself.
///
/// [tables] must list a table after every table it references, because
/// PostgreSQL checks a foreign key target when the table is created.
Future<void> migrateToVersion1(
  Migrator migrator,
  Iterable<TableInfo<Table, Object?>> tables,
) async {
  for (final table in tables) {
    await migrator.createTable(table);
    for (final sql in customIndexes[table.actualTableName] ?? const []) {
      await migrator.database.customStatement(sql);
    }
  }
}
