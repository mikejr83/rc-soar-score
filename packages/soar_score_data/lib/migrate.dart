import 'package:drift/drift.dart';

import 'schema/custom_indexes.dart';

/// Creates the current schema for a new database, then its custom indexes.
///
/// [tables] must list a table after every table it references, because
/// PostgreSQL checks a foreign key target when the table is created.
Future<void> createCurrentSchema(
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
