import 'package:drift/drift.dart';

import '../../contests_table.dart';
import '../enum_values.dart';
import 'score_attempts_table.dart';
import 'score_placeholders_table.dart';

/// `ReviewRequest`: the table of review requests, one column per model field.
@DataClassName('ReviewRequestData')
class ReviewRequests extends Table {
  TextColumn get id => text()();
  TextColumn get contestId =>
      text().references(Contests, #id, onDelete: KeyAction.cascade)();
  TextColumn get scorePlaceholderId =>
      text().references(ScorePlaceholders, #id)();
  TextColumn get proposedComponents => text()();
  TextColumn get participantMessage => text().nullable()();
  TextColumn get requesterId => text()();
  IntColumn get baseScoreRevision => integer()();
  TextColumn get requestedAt => text()();
  TextColumn get state => text().check(state.isIn(reviewRequestStateValues))();
  TextColumn get decisionActorId => text().nullable()();
  TextColumn get decisionTime => text().nullable()();
  TextColumn get decisionMessage => text().nullable()();
  TextColumn get resultingAttemptId =>
      text().nullable().references(ScoreAttempts, #id)();
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (state <> 'Submitted' OR (decision_actor_id IS NULL AND decision_time IS NULL AND resulting_attempt_id IS NULL))",
  ];
}

/// Columns of `review_requests` that hold JSON as text.
const reviewRequestsJsonColumns = <String>{'proposed_components'};
