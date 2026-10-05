import 'package:drift/drift.dart';

import 'discipline_profiles_table.dart';

/// `DisciplineValidation`: the table of discipline validations, one column per model field.
@DataClassName('DisciplineValidationData')
class DisciplineValidations extends Table {
  TextColumn get id => text()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get fieldKeys => text()();
  TextColumn get constraintType => text()();
  TextColumn get description => text().nullable()();
  TextColumn get appliesTo => text().nullable()();
  TextColumn get message => text().nullable()();
  IntColumn get displayOrder => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {disciplineProfileId, fieldKeys, constraintType},
  ];
}

/// Columns of `discipline_validations` that hold JSON as text.
const disciplineValidationsJsonColumns = <String>{'field_keys', 'applies_to'};
