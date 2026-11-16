import 'dart:async';

import 'package:drift/drift.dart';
import 'package:postgres/postgres.dart' show ServerException;
import 'package:soar_score_core/soar_score_core.dart'
    show ContestBusyError, SyncScopeKey;

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
/// for a lock this call holds. The lock wait is bounded by [lockTimeout]
/// (default [contestGateLockTimeout]); a timeout (PostgreSQL 55P03) or a
/// deadlock (40P01), from the gate or from any statement of [body], is thrown
/// as a [ContestBusyError] after the transaction rolled back, so nothing was
/// kept and the caller may repeat the request (the API answers 503 with
/// `retry-after`). `lock_timeout` is set with
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
  Future<T> Function() body, {
  String lockTimeout = contestGateLockTimeout,
}) async {
  final outer = pendingAnnouncements;
  final pending = outer ?? <SyncScopeKey>{};
  final result = await mapContestBusy(
    () => _gated(db, contestId, body, lockTimeout, pending, outer),
  );
  if (outer == null) pending.forEach(db.announceLocalChange);
  return result;
}

/// Runs [body] and throws a [ContestBusyError] for a PostgreSQL lock timeout
/// (55P03) or deadlock (40P01) it raises; every other error passes through.
///
/// Used where a statement can wait on a lock (the gate, a unit of work, a row
/// lock), so callers inside a gate see the retryable error itself and can let
/// it escape instead of reporting a failed entry.
Future<T> mapContestBusy<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on ServerException catch (error) {
    if (_busyCodes.contains(error.code)) throw ContestBusyError(cause: error);
    rethrow;
  }
}

/// PostgreSQL's lock timeout (`lock_not_available`) and deadlock
/// (`deadlock_detected`) codes: the request lost its turn and nothing was
/// kept.
const _busyCodes = {'55P03', '40P01'};

Future<T> _gated<T>(
  SoarScoreDatabase db,
  String contestId,
  Future<T> Function() body,
  String lockTimeout,
  Set<SyncScopeKey> pending,
  Set<SyncScopeKey>? outer,
) => runZoned(
  () => db.transaction(() async {
    if (db.executor.dialect == SqlDialect.postgres) {
      if (outer == null) {
        await db.customStatement("SET LOCAL lock_timeout = '$lockTimeout'");
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
