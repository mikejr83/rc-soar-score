import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'matrix_revisions_table.dart';

/// `Round`: the table of rounds, one column per model field.
@DataClassName('RoundData')
class Rounds extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get matrixRevisionId => text().references(MatrixRevisions, #id)();
  IntColumn get ordinal => integer()();
  IntColumn get groupCount => integer()();
  TextColumn get status => text().check(status.isIn(roundStatusValues))();
  // Deferred: a redraw marks the old round before it inserts the new one,
  // because the unique index on live ordinals would otherwise see both.
  TextColumn get supersededByRoundId => text().nullable().customConstraint(
    'NULL REFERENCES rounds (id) DEFERRABLE INITIALLY DEFERRED',
  )();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {matrixRevisionId, ordinal},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (ordinal >= 1 AND group_count >= 1)',
  ];
}

/// Columns of `rounds` that hold JSON as text.
const roundsJsonColumns = <String>{};
