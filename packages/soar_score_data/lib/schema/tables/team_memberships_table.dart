import 'package:drift/drift.dart';

import '../../contests_table.dart';
import 'contest_participations_table.dart';
import 'teams_table.dart';

/// `TeamMembership`: the table of team memberships, one column per model field.
@DataClassName('TeamMembershipData')
class TeamMemberships extends Table {
  TextColumn get id => text()();
  TextColumn get teamId => text().references(Teams, #id)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {teamId, contestParticipationId},
  ];
}

/// Columns of `team_memberships` that hold JSON as text.
const teamMembershipsJsonColumns = <String>{};
