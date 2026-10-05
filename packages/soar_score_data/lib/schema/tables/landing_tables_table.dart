import 'package:drift/drift.dart';

import '../enum_values.dart';

/// `LandingTable`: the table of landing tables, one column per model field.
@DataClassName('LandingTableData')
class LandingTables extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get inputUnit =>
      text().check(inputUnit.isIn(landingInputUnitValues))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `landing_tables` that hold JSON as text.
const landingTablesJsonColumns = <String>{};
