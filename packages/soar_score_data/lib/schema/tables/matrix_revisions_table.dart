import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';

/// `MatrixRevision`: the table of matrix revisions, one column per model field.
@DataClassName('MatrixRevisionData')
class MatrixRevisions extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  IntColumn get revisionNumber => integer()();
  TextColumn get previousRevisionId =>
      text().nullable().references(MatrixRevisions, #id)();
  IntColumn get firstRound => integer()();
  IntColumn get lastRound => integer()();
  TextColumn get drawMode => text().check(drawMode.isIn(drawModeValues))();
  IntColumn get randomSeed => integer()();
  TextColumn get algorithmVersion => text()();
  TextColumn get drawConfig => text()();
  TextColumn get seedingSnapshot => text()();
  TextColumn get fairnessSummary => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get createdAt => text()();
  TextColumn get finalizedBy => text().nullable()();
  TextColumn get finalizedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestId, revisionNumber},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (first_round >= 1 AND first_round <= last_round)',
  ];
}

/// Columns of `matrix_revisions` that hold JSON as text.
const matrixRevisionsJsonColumns = <String>{
  'draw_config',
  'seeding_snapshot',
  'fairness_summary',
};
