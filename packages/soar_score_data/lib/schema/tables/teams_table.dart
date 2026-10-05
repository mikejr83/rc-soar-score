import 'package:drift/drift.dart';

import '../../contests_table.dart';

/// `Team`: the table of teams, one column per model field.
@DataClassName('TeamData')
class Teams extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestId, name},
  ];
}

/// Columns of `teams` that hold JSON as text.
const teamsJsonColumns = <String>{};
