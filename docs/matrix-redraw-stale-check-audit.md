# Stale matrix redraw check audit

Review of the stale check in `MatrixRevisionRepository.appendRedraw`
(`packages/soar_score_data/lib/repositories/matrix_revision_repository.dart`),
added by PR #655, which refuses a stale matrix redraw before it stores.
Checked on 2026-10-29.

## Findings

### 1. The stale check is not transactional — invalid

The claim: the check calls `latestForContest` on the repository's own
connection instead of the transaction's, so two concurrent redraws can both
pass it and only the successor unique index stops the double write; on
SQLite the second read may also block; and the comment saying it is
"re-checked in the transaction" is wrong.

**Evaluation: invalid.**

- **The read is inside the transaction, on the transaction's connection.**
  The check runs inside the unit of work's body, and the unit of work runs
  that body inside the database's transaction. Drift runs the transaction
  body in a zone whose engine is the transaction itself, and every statement
  issued in that zone — the check's `customSelect` included — runs on that
  engine. There is no second connection: the repository's database and the
  unit of work's database are the same instance, so the read happens between
  the transaction's `BEGIN` and `COMMIT` on the same connection as its
  writes.
- **The concurrent race is the intended design, not a gap.** On PostgreSQL,
  two redraws that read the same newest revision can both pass the check;
  the successor revision's unique `(contest_id, revision_number)` index lets
  exactly one commit, and the loser's unique violation is mapped back to
  `stale_matrix`. The contract documents this, and the repository test
  "a redraw that loses a race for the successor stores nothing" exercises
  it: one winner, one `stale_matrix`, and the loser stores no rows.
- **On SQLite the second check cannot interleave.** A native profile has one
  connection, and the database serializes statements on it. The second
  transaction's check runs after the first commits, sees the successor
  revision, and is refused in the transaction before any insert — no double
  write, no busy error.

**Resolution.** No change. The check is transactional, the comment is
accurate, and the only window left — the read-then-insert on PostgreSQL —
is the one the unique index and the violation mapping close.
