import 'package:drift/drift.dart';

import 'landing_tables_table.dart';

/// `LandingResult`: the table of landing results, one column per model field.
@DataClassName('LandingResultData')
class LandingResults extends Table {
  TextColumn get id => text()();
  TextColumn get landingTableId => text().references(LandingTables, #id)();
  TextColumn get entryKey => text()();
  TextColumn get displayValue => text()();
  IntColumn get pointValue => integer()();
  IntColumn get ordinalPosition => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {landingTableId, entryKey},
    {landingTableId, ordinalPosition},
  ];
}

/// Columns of `landing_results` that hold JSON as text.
const landingResultsJsonColumns = <String>{};
