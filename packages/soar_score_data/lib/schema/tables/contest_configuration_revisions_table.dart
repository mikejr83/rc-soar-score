import 'package:drift/drift.dart';

import '../../contests_table.dart';
import 'contest_configuration_presets_table.dart';
import 'discipline_profiles_table.dart';
import 'landing_tables_table.dart';

/// `ContestConfigurationRevision`: the table of contest configuration revisions, one column per model field.
@DataClassName('ContestConfigurationRevisionData')
class ContestConfigurationRevisions extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  IntColumn get revisionNumber => integer()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get sourcePresetId =>
      text().references(ContestConfigurationPresets, #id).nullable()();
  TextColumn get config => text()();
  TextColumn get landingTableId =>
      text().references(LandingTables, #id).nullable()();
  TextColumn get createdBy => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestId, revisionNumber},
  ];
}

/// Columns of `contest_configuration_revisions` that hold JSON as text.
const contestConfigurationRevisionsJsonColumns = <String>{'config'};
