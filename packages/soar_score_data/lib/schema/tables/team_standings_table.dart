import 'package:drift/drift.dart';

import '../../contests_table.dart';
import 'contest_configuration_revisions_table.dart';
import 'matrix_revisions_table.dart';
import 'teams_table.dart';

/// `TeamStanding`: the table of team standings, one column per model field.
@DataClassName('TeamStandingData')
class TeamStandings extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get teamId => text().references(Teams, #id)();
  IntColumn get asOfRound => integer()();
  IntColumn get place => integer()();
  BoolColumn get isTied => boolean()();
  RealColumn get teamScore => real()();
  TextColumn get countedParticipations => text()();
  BoolColumn get isPreliminary => boolean()();
  TextColumn get configRevisionId =>
      text().references(ContestConfigurationRevisions, #id)();
  TextColumn get matrixRevisionId => text().references(MatrixRevisions, #id)();
  TextColumn get calculationVersion => text()();
  TextColumn get computedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {teamId, asOfRound},
  ];
}

/// Columns of `team_standings` that hold JSON as text.
const teamStandingsJsonColumns = <String>{'counted_participations'};
