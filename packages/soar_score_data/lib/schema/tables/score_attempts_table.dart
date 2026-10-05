import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'contest_configuration_revisions_table.dart';
import 'matrix_revisions_table.dart';
import 'score_placeholders_table.dart';

/// `ScoreAttempt`: the table of score attempts, one column per model field.
@DataClassName('ScoreAttemptData')
class ScoreAttempts extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get scorePlaceholderId =>
      text().references(ScorePlaceholders, #id)();
  TextColumn get configRevisionId =>
      text().references(ContestConfigurationRevisions, #id)();
  TextColumn get matrixRevisionId => text().references(MatrixRevisions, #id)();
  TextColumn get rawComponents => text()();
  TextColumn get actorId => text()();
  TextColumn get authority => text().check(authority.isIn(authorityValues))();
  TextColumn get invitationId => text().nullable()();
  TextColumn get sourceDevice => text().nullable()();
  TextColumn get clientMutationId => text()();
  IntColumn get baseScoreRevision => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {contestId, clientMutationId},
  ];
}

/// Columns of `score_attempts` that hold JSON as text.
const scoreAttemptsJsonColumns = <String>{'raw_components'};
