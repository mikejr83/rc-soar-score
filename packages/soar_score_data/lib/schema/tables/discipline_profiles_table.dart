import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'landing_tables_table.dart';

/// `DisciplineProfile`: the table of discipline profiles, one column per model field.
@DataClassName('DisciplineProfileData')
class DisciplineProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get type => text().check(type.isIn(disciplineTypeValues))();
  IntColumn get version => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category =>
      text().check(category.isIn(disciplineCategoryValues))();
  TextColumn get defaultLandingTableId =>
      text().references(LandingTables, #id).nullable()();
  TextColumn get defaultOptions => text().nullable()();
  TextColumn get status => text().check(status.isIn(profileStatusValues))();
  TextColumn get supersededBy =>
      text().references(DisciplineProfiles, #id).nullable()();
  TextColumn get createdBy => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedBy => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {type, version},
  ];
}

/// Columns of `discipline_profiles` that hold JSON as text.
const disciplineProfilesJsonColumns = <String>{'default_options'};
