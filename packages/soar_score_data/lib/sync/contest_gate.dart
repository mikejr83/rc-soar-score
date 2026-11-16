import 'dart:async';

import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' show SyncScopeKey;

import '../database.dart';
import 'pending_announcements.dart';
import 'sql_placeholders.dart';

/// How long a score writer waits for the contest's gate on PostgreSQL before
/// the statement fails (`lock_timeout`), so a stuck holder surfaces as an
/// error and not as a request that hangs for ever.
const contestGateLockTimeout = '30s';

/// Runs [body] in a transaction that holds the contest's score gate.
///
/// On PostgreSQL the gate is a transaction-scoped advisory lock taken before
/// [body] reads anything, so concurrent gated writers of one contest, on this
/// or another server instance, run one after another and each reads what the
/// previous committed. That holds at READ COMMITTED, PostgreSQL's default and
/// what the server uses: each statement then sees every commit made before the
/// lock was granted. A stricter isolation level would take its snapshot at the
/// first statement, before the lock, and is not supported here.
///
/// SQLite takes the writer lock when the transaction begins (Drift's native
/// executor starts it with `BEGIN IMMEDIATE`, drift 2.35 `Sqlite3Delegate`),
/// so the reads in [body] cannot be overtaken.
///
/// Called inside another gate (or any transaction) it opens a savepoint of
/// that transaction: the lock stays held and the outer commit decides.
///
/// Local-change announcements made by units of work inside [body] are held
/// back and made once, after the outermost commit; a rollback makes none.
///
/// Do not await work on another database connection from [body]: that work
/// cannot see this transaction's writes and, if it needs the same gate, waits
/// for a lock this call holds. The lock wait is bounded by
/// [contestGateLockTimeout]; a timeout (PostgreSQL 55P03) or a deadlock
/// (40P01) surfaces as the database's own error, which the API answers as a
/// server error; the caller may retry the request. `lock_timeout` is set with
/// `SET LOCAL`, so it stays in force for the rest of an enclosing transaction
/// that was not itself a gate.
///
/// A gate nested for a different contest takes a second lock; two writers
/// taking two contests in opposite orders can deadlock, so a writer holds one
/// contest's gate at a time. A rolled-back savepoint whose outer body carries
/// on still lets its scopes be announced (a spurious wake-up, never a missed
/// one).
Future<T> withContestScoreGate<T>(
  SoarScoreDatabase db,
  String contestId,
  Future<T> Function() body,
) async {
  final outer = pendingAnnouncements;
  final pending = outer ?? <SyncScopeKey>{};
  final result = await runZoned(
    () => db.transaction(() async {
      if (db.executor.dialect == SqlDialect.postgres) {
        if (outer == null) {
          await db.customStatement(
            "SET LOCAL lock_timeout = '$contestGateLockTimeout'",
          );
        }
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
    }),
    zoneValues: {pendingAnnouncementsKey: pending},
  );
  if (outer == null) pending.forEach(db.announceLocalChange);
  return result;
}
