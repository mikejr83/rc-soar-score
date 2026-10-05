import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'discipline_profiles_table.dart';

/// `DisciplineConfigField`: the table of discipline config fields, one column per model field.
@DataClassName('DisciplineConfigFieldData')
class DisciplineConfigFields extends Table {
  TextColumn get id => text()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get fieldKey => text()();
  TextColumn get fieldType =>
      text().check(fieldType.isIn(configFieldTypeValues))();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get unit => text().nullable()();
  BoolColumn get required => boolean()();
  TextColumn get defaultValue => text().nullable()();
  TextColumn get options => text().nullable()();
  TextColumn get validation => text().nullable()();
  IntColumn get displayOrder => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {disciplineProfileId, fieldKey},
  ];
}

/// Columns of `discipline_config_fields` that hold JSON as text.
const disciplineConfigFieldsJsonColumns = <String>{
  'default_value',
  'options',
  'validation',
};
