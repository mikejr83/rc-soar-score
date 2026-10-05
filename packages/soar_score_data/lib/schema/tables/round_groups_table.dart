import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'rounds_table.dart';

/// `RoundGroup`: the table of round groups, one column per model field.
@DataClassName('RoundGroupData')
class RoundGroups extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get roundId => text().references(Rounds, #id)();
  IntColumn get groupNumber => integer()();
  TextColumn get status => text().check(status.isIn(groupStatusValues))();
  TextColumn get lockedBy => text().nullable()();
  TextColumn get lockedAt => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {roundId, groupNumber},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (group_number >= 1)',
    "CHECK ((status = 'Locked') = (locked_at IS NOT NULL))",
  ];
}

/// Columns of `round_groups` that hold JSON as text.
const roundGroupsJsonColumns = <String>{};
