import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_participations_table.dart';
import 'matrix_revisions_table.dart';
import 're_flights_table.dart';
import 'rounds_table.dart';

/// `MatrixAssignment`: the table of matrix assignments, one column per model field.
@DataClassName('MatrixAssignmentData')
class MatrixAssignments extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get matrixRevisionId => text().references(MatrixRevisions, #id)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get scheduledRoundId => text().references(Rounds, #id)();
  TextColumn get creditedRoundId => text().references(Rounds, #id)();
  IntColumn get group => integer()();
  IntColumn get lane => integer().nullable()();
  IntColumn get flightSequence => integer()();
  TextColumn get assignmentType =>
      text().check(assignmentType.isIn(assignmentTypeValues))();
  TextColumn get sourceAssignmentId =>
      text().nullable().references(MatrixAssignments, #id)();
  TextColumn get reFlightId => text().nullable().references(ReFlights, #id)();
  // Deferred: a move marks the old row before it inserts the new one, because
  // the unique index on live assignments would otherwise see both at once.
  TextColumn get supersededByAssignmentId => text().nullable().customConstraint(
    'NULL REFERENCES matrix_assignments (id) DEFERRABLE INITIALLY DEFERRED',
  )();
  TextColumn get actorId => text()();
  TextColumn get reason => text().nullable()();
  TextColumn get existingScoreHandling =>
      text().check(existingScoreHandling.isIn(existingScoreHandlingValues))();
  IntColumn get resetScoreRevision => integer().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK ("group" >= 1 AND flight_sequence >= 1)',
    "CHECK ((assignment_type IN ('Moved', 'Reflight')) = (source_assignment_id IS NOT NULL))",
    "CHECK ((assignment_type = 'Reflight') = (re_flight_id IS NOT NULL))",
    "CHECK (assignment_type = 'Original' OR reason IS NOT NULL)",
    "CHECK (reset_score_revision IS NULL OR existing_score_handling = 'Reset')",
  ];
}

/// Columns of `matrix_assignments` that hold JSON as text.
const matrixAssignmentsJsonColumns = <String>{};
