import 'package:drift/drift.dart';

import '../database.dart';
import 'sql_placeholders.dart';

/// Runs [body] in a transaction that holds the contest's score gate.
///
/// On PostgreSQL the gate is a transaction-scoped advisory lock taken before
/// [body] reads anything, so concurrent score writers of one contest, on this
/// or another server instance, run one after another and each reads what the
/// previous committed. SQLite takes the writer lock when the transaction
/// begins (Drift's native executor starts `BEGIN IMMEDIATE`), so the reads in
/// [body] cannot be overtaken. Called inside a gate of the same transaction
/// it joins it: the lock is already held.
Future<T> withContestScoreGate<T>(
  SoarScoreDatabase db,
  String contestId,
  Future<T> Function() body,
) => db.transaction(() async {
  if (db.executor.dialect == SqlDialect.postgres) {
    await db
        .customSelect(
          portableSql(
            db,
            'SELECT pg_advisory_xact_lock(hashtextextended(?, 0))',
          ),
          variables: [Variable<String>('contest_scores:$contestId')],
        )
        .get();
  }
  return body();
});
