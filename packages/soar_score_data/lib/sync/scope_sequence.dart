import 'package:drift/drift.dart';

import '../database.dart';
import 'sql_placeholders.dart';

/// The highest sequence in a scope's log, or 0 for an empty log.
///
/// Call it inside a transaction that is about to take the next sequence. On
/// PostgreSQL it first takes a transaction-scoped advisory lock on the scope,
/// so two writers (a sync exchange and a hosted write, on this or another
/// server instance) never read the same maximum: the second waits for the
/// first to commit and then sees its record. SQLite has one writer at a time.
Future<int> highestScopeSequence(
  SoarScoreDatabase db, {
  required String column,
  required String scopeId,
}) async {
  if (db.executor.dialect == SqlDialect.postgres) {
    await db
        .customSelect(
          portableSql(
            db,
            'SELECT pg_advisory_xact_lock(hashtextextended(?, 0))',
          ),
          variables: [Variable<String>('mutation_records:$column:$scopeId')],
        )
        .get();
  }
  final row = await db
      .customSelect(
        portableSql(
          db,
          'SELECT MAX(sequence) AS highest FROM mutation_records '
          'WHERE $column = ?',
        ),
        variables: [Variable<String>(scopeId)],
        readsFrom: {db.mutationRecords},
      )
      .getSingle();
  return row.read<int?>('highest') ?? 0;
}
