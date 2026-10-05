import 'package:drift/drift.dart';

import '../../contests_table.dart';
import 'contest_configuration_revisions_table.dart';
import 'contest_participations_table.dart';
import 'matrix_revisions_table.dart';

/// `ParticipationStanding`: the table of participation standings, one column per model field.
@DataClassName('ParticipationStandingData')
class ParticipationStandings extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  IntColumn get asOfRound => integer()();
  IntColumn get place => integer()();
  BoolColumn get isTied => boolean()();
  RealColumn get rawTotal => real()();
  TextColumn get droppedRounds => text()();
  RealColumn get penaltyTotal => real()();
  RealColumn get overallScore => real()();
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
    {contestParticipationId, asOfRound},
  ];
}

/// Columns of `participation_standings` that hold JSON as text.
const participationStandingsJsonColumns = <String>{'dropped_rounds'};
