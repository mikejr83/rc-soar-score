import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_configuration_revisions_table.dart';
import 'contest_participations_table.dart';
import 'matrix_revisions_table.dart';
import 'official_scores_table.dart';
import 'rounds_table.dart';
import 'score_placeholders_table.dart';

/// `FlightResult`: the table of flight results, one column per model field.
@DataClassName('FlightResultData')
class FlightResults extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get scorePlaceholderId =>
      text().references(ScorePlaceholders, #id)();
  TextColumn get officialScoreId => text().references(OfficialScores, #id)();
  TextColumn get contestParticipationId =>
      text().references(ContestParticipations, #id)();
  TextColumn get creditedRoundId => text().references(Rounds, #id)();
  TextColumn get outcome => text().check(outcome.isIn(flightOutcomeValues))();
  RealColumn get rawPoints => real()();
  RealColumn get landingPoints => real().nullable()();
  RealColumn get flightPenaltyPoints => real().nullable()();
  IntColumn get cumulativePenalty => integer().nullable()();
  RealColumn get groupScore => real()();
  BoolColumn get isSelected => boolean()();
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
    {scorePlaceholderId},
  ];

  @override
  List<String> get customConstraints => ['CHECK (raw_points >= 0)'];
}

/// Columns of `flight_results` that hold JSON as text.
const flightResultsJsonColumns = <String>{};
