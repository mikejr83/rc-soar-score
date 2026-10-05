import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'participant_profiles_table.dart';
import 'roles_table.dart';

/// `ContestParticipation`: the table of contest participations, one column per model field.
@DataClassName('ContestParticipationData')
class ContestParticipations extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get participantProfileId =>
      text().references(ParticipantProfiles, #id)();
  TextColumn get classification => text().nullable()();
  TextColumn get roleId => text().references(Roles, #id)();
  TextColumn get roleName => text()();
  TextColumn get roleType => text().check(roleType.isIn(roleTypeValues))();
  IntColumn get participantNumber => integer().nullable()();
  TextColumn get scoringUuid => text()();
  IntColumn get retiredAtRound => integer().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestId, participantNumber},
    {contestId, scoringUuid},
    {contestId, participantProfileId},
  ];
}

/// Columns of `contest_participations` that hold JSON as text.
const contestParticipationsJsonColumns = <String>{};
