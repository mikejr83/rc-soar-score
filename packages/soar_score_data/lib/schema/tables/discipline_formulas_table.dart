import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'discipline_profiles_table.dart';

/// `DisciplineFormula`: the table of discipline formulas, one column per model field.
@DataClassName('DisciplineFormulaData')
class DisciplineFormulas extends Table {
  TextColumn get id => text()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get formulaKey => text()();
  TextColumn get description => text().nullable()();
  TextColumn get formulaText => text()();
  TextColumn get formulaType =>
      text().check(formulaType.isIn(formulaTypeValues))();
  TextColumn get inputs => text()();
  TextColumn get outputs => text().nullable()();
  TextColumn get dependsOn => text()();
  BoolColumn get isPrimary => boolean()();
  IntColumn get displayOrder => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {disciplineProfileId, formulaKey},
  ];
}

/// Columns of `discipline_formulas` that hold JSON as text.
const disciplineFormulasJsonColumns = <String>{
  'inputs',
  'outputs',
  'depends_on',
};
