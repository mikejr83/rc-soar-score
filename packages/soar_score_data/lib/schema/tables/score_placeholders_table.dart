import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_participations_table.dart';
import 'matrix_assignments_table.dart';

/// `ScorePlaceholder`: the table of score placeholders, one column per model field.
@DataClassName('ScorePlaceholderData')
class ScorePlaceholders extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get assignmentId => text().references(MatrixAssignments, #id)();
  TextColumn get state =>
      text().check(state.isIn(scorePlaceholderStateValues))();
  IntColumn get scoreRevision => integer()();
  TextColumn get currentAttemptId => text().nullable()();
  TextColumn get lockedBy => text().nullable()();
  TextColumn get lockedAt => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {assignmentId},
  ];

  @override
  List<String> get customConstraints => [
    'CHECK (score_revision >= 0)',
    'CHECK ((locked_by IS NULL) = (locked_at IS NULL))',
  ];
}

/// Columns of `score_placeholders` that hold JSON as text.
const scorePlaceholdersJsonColumns = <String>{};
