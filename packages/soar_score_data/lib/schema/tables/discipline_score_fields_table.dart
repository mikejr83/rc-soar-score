import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'discipline_profiles_table.dart';

/// `DisciplineScoreField`: the table of discipline score fields, one column per model field.
@DataClassName('DisciplineScoreFieldData')
class DisciplineScoreFields extends Table {
  TextColumn get id => text()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get fieldKey => text()();
  TextColumn get fieldType =>
      text().check(fieldType.isIn(scoreFieldTypeValues))();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get fieldKind =>
      text().check(fieldKind.isIn(scoreFieldKindValues))();
  TextColumn get unit => text().nullable()();
  IntColumn get precision => integer().nullable()();
  BoolColumn get required => boolean()();
  TextColumn get defaultValue => text().nullable()();
  TextColumn get options => text().nullable()();
  TextColumn get validation => text().nullable()();
  IntColumn get displayOrder => integer()();
  BoolColumn get isZeroReason => boolean()();
  TextColumn get zeroReasonCode => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {disciplineProfileId, fieldKey},
  ];
}

/// Columns of `discipline_score_fields` that hold JSON as text.
const disciplineScoreFieldsJsonColumns = <String>{
  'default_value',
  'options',
  'validation',
};
