import 'package:drift/drift.dart';

import 'database_profile.dart';
import 'table_group.dart';

/// The group of every table, by SQL table name.
///
/// A table that is not listed cannot be created, and a test fails if one is
/// missing, so no table can silently reach the wrong executor.
const tableGroupByName = <String, TableGroup>{'contests': TableGroup.contest};

/// The tables of [all] that [profile] creates, using [groups] (by default
/// [tableGroupByName]) to find each table's group.
List<TableInfo<Table, Object?>> tablesFor(
  DatabaseProfile profile,
  Iterable<TableInfo<Table, Object?>> all, {
  Map<String, TableGroup> groups = tableGroupByName,
}) => [
  for (final table in all)
    if (profile.groups.contains(
      groups[table.actualTableName] ??
          (throw StateError('Table ${table.actualTableName} has no group')),
    ))
      table,
];
