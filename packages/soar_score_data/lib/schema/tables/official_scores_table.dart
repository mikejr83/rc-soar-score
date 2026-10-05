import 'package:drift/drift.dart';

import '../../contests_table.dart';
import 'score_attempts_table.dart';
import 'score_placeholders_table.dart';

/// `OfficialScore`: the table of official scores, one column per model field.
@DataClassName('OfficialScoreData')
class OfficialScores extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get scorePlaceholderId =>
      text().references(ScorePlaceholders, #id)();
  TextColumn get scoreAttemptId => text().references(ScoreAttempts, #id)();
  IntColumn get scoreRevision => integer()();
  TextColumn get components => text()();
  TextColumn get setAt => text()();
  TextColumn get setBy => text()();
  TextColumn get reason => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {scorePlaceholderId, scoreRevision},
  ];

  @override
  List<String> get customConstraints => ['CHECK (score_revision >= 1)'];
}

/// Columns of `official_scores` that hold JSON as text.
const officialScoresJsonColumns = <String>{'components'};
