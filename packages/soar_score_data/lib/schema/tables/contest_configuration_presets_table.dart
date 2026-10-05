import 'package:drift/drift.dart';

import 'discipline_profiles_table.dart';
import 'landing_tables_table.dart';

/// `ContestConfigurationPreset`: the table of contest configuration presets, one column per model field.
@DataClassName('ContestConfigurationPresetData')
class ContestConfigurationPresets extends Table {
  TextColumn get id => text()();
  TextColumn get ownerAccountId => text()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get config => text()();
  TextColumn get landingTableId =>
      text().references(LandingTables, #id).nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Columns of `contest_configuration_presets` that hold JSON as text.
const contestConfigurationPresetsJsonColumns = <String>{'config'};
