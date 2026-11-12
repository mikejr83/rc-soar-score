import 'package:drift/drift.dart';

import '../database.dart';
import 'sql_placeholders.dart';

/// Fills `score_placeholders.current_attempt_id` where a slot has a score but
/// no pointer, and returns the number of slots it filled.
///
/// The rule is shared by the version 1 to 2 upgrade, contest import and
/// replication of pre-upgrade changes: the attempt behind the slot's current
/// official score, else the slot's latest accepted attempt. A slot with no
/// score, or one that already has a pointer, is left as it is, so pointers
/// written by current code are never replaced. Safe to repeat.
///
/// Limit it with [contestId] or [placeholderId]; with neither it covers the
/// whole database.
Future<int> fillCurrentAttemptIds(
  SoarScoreDatabase db, {
  String? contestId,
  String? placeholderId,
}) {
  final scope = StringBuffer();
  final variables = <Variable<Object>>[];
  if (contestId != null) {
    scope.write(' AND p.contest_id = ?');
    variables.add(Variable<String>(contestId));
  }
  if (placeholderId != null) {
    scope.write(' AND p.id = ?');
    variables.add(Variable<String>(placeholderId));
  }
  return db.customUpdate(
    portableSql(db, '''
UPDATE score_placeholders SET current_attempt_id = COALESCE(
  (SELECT o.score_attempt_id FROM official_scores o
    WHERE o.score_placeholder_id = score_placeholders.id
    ORDER BY o.score_revision DESC LIMIT 1),
  (SELECT a.id FROM score_attempts a
    WHERE a.score_placeholder_id = score_placeholders.id
    ORDER BY a.accepted_at DESC, a.id DESC LIMIT 1))
WHERE current_attempt_id IS NULL AND score_revision > 0
  AND id IN (SELECT p.id FROM score_placeholders p WHERE 1 = 1$scope)'''),
    variables: variables,
    updates: {db.scorePlaceholders},
  );
}
