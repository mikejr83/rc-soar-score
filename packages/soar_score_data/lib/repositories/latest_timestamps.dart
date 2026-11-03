import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../sync/sql_placeholders.dart';

/// The latest value of the timestamp [column] of [table] for each of
/// [contestIds], in one query. A contest with no row is absent.
///
/// [table] and [column] are schema names, never user input; the ids travel
/// as variables. Timestamps are stored as UTC ISO text.
Future<Map<core.Id, DateTime>> latestTimestampByContest(
  SoarScoreDatabase db, {
  required String table,
  required String column,
  required Iterable<core.Id> contestIds,
}) async {
  final wanted = contestIds.toSet().toList();
  if (wanted.isEmpty) return {};
  final rows = await db
      .customSelect(
        portableSql(
          db,
          'SELECT contest_id, MAX($column) AS latest FROM $table '
          'WHERE contest_id IN (${List.filled(wanted.length, '?').join(', ')}) '
          'GROUP BY contest_id',
        ),
        variables: [for (final id in wanted) Variable<String>(id.value)],
      )
      .get();
  return {
    for (final row in rows)
      core.Id.parse(row.read<String>('contest_id')): DateTime.parse(
        row.read<String>('latest'),
      ).toUtc(),
  };
}
