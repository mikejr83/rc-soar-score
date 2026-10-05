import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_participations_table.dart';
import 'matrix_assignments_table.dart';
import 're_flights_table.dart';

/// `ReFlightParticipant`: the table of re flight participants, one column per model field.
@DataClassName('ReFlightParticipantData')
class ReFlightParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get reFlightId => text().references(ReFlights, #id)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get role =>
      text().check(role.isIn(reFlightParticipantRoleValues))();
  TextColumn get excludedReason =>
      text().nullable().check(excludedReason.isIn(excludedReasonValues))();
  IntColumn get drawPosition => integer().nullable()();
  TextColumn get response =>
      text().check(response.isIn(reFlightResponseValues))();
  TextColumn get respondedBy =>
      text().nullable().check(respondedBy.isIn(responseActorValues))();
  TextColumn get respondedAt => text().nullable()();
  TextColumn get notificationState =>
      text().check(notificationState.isIn(notificationStateValues))();
  TextColumn get notifiedAt => text().nullable()();
  TextColumn get acknowledgedAt => text().nullable()();
  TextColumn get assignmentId =>
      text().nullable().references(MatrixAssignments, #id)();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {reFlightId, contestParticipationId},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK ((role = 'Excluded') = (excluded_reason IS NOT NULL))",
  ];
}

/// Columns of `re_flight_participants` that hold JSON as text.
const reFlightParticipantsJsonColumns = <String>{};
