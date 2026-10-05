import 'package:drift/drift.dart';

import '../enum_values.dart';
import 'discipline_profiles_table.dart';

/// `DisciplineRule`: the table of discipline rules, one column per model field.
@DataClassName('DisciplineRuleData')
class DisciplineRules extends Table {
  TextColumn get id => text()();
  TextColumn get disciplineProfileId =>
      text().references(DisciplineProfiles, #id)();
  TextColumn get ruleKey => text()();
  TextColumn get ruleType => text().check(ruleType.isIn(ruleTypeValues))();
  TextColumn get condition => text().nullable()();
  TextColumn get effect => text().nullable()();
  TextColumn get appliesTo => text().nullable()();
  TextColumn get dependsOn => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get autoScoreZero => boolean()();
  TextColumn get affectsOtherFields => text()();
  IntColumn get displayOrder => integer()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {disciplineProfileId, ruleKey},
  ];
}

/// Columns of `discipline_rules` that hold JSON as text.
const disciplineRulesJsonColumns = <String>{
  'applies_to',
  'depends_on',
  'affects_other_fields',
};
