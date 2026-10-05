import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `Role`: the table of roles, one column per model field.
@DataClassName('RoleData')
class Roles extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text().nullable()();
  TextColumn get displayName => text()();
  TextColumn get type => text().check(type.isIn(roleTypeValues))();
  TextColumn get archivedAt => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `roles` that hold JSON as text.
const rolesJsonColumns = <String>{};
