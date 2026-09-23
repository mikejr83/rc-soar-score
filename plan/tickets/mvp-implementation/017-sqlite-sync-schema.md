# Ticket 017 — SQLite Sync Schema (Offline Synchronization Fields)

- **Category:** Data
- **Priority:** Medium
- **Status:** Open

## Context

Ticket 007 scaffolded `soar_score_data_sqlite` with a minimal `contests` table only, and recorded the decision that sync-related schema fields are **deferred to this ticket** (rather than included in the initial scaffold schema). `offline-synchronization.md` defines what the local store must retain: unsent mutations with their unique client identifiers, server-time ordering, durable sync cursors, tombstones until acknowledged, and audit history.

## Work Items

- [ ] Add the local sync schema to `soar_score_data_sqlite` (drift 2.x table DSL, schema version 2 migration):
  - `client_mutation_log` — unsent mutations: unique client mutation id (composite unique `(contest_id, client_mutation_id)` for idempotency), payload, base revision, actor, authority, source device, client timestamp, created time.
  - `sync_cursors` — per-contest last-acknowledged `contest_mutation_seq` (monotonically increasing, per `data/README.md`), durable across restarts.
  - `tombstones` — soft-deleted entity records with deletion time, retained 90 days or until contest archiving + 90 days.
  - Sync bookkeeping columns on `contests` (e.g. `revision`, `base_revision`, `last_modified_at` as UTC) as required by the sync protocol.
- [ ] Add the matching repositories (`repositories/`) implementing `soar_score_core` interfaces; file and link any new abstract interface this requires in `soar_score_core`.
- [ ] Add tests against an in-memory database proving: unsent mutations are retained and replayable, cursor only advances after changes are stored, and tombstones block resurrection by older changes.

## Acceptance Criteria

- [ ] All requirements 1–8 of `offline-synchronization.md`'s *Synchronization Requirements* are satisfiable from the local schema alone (server-side behavior remains server work).
- [ ] `dart analyze` and `dart test` pass from the package directory.

## Dependencies

- [007-scaffold-data-package.md](007-scaffold-data-package.md)
- [006-scaffold-core-package.md](006-scaffold-core-package.md)

## Sources

- `plan/architecture-requirements/offline-synchronization.md`
- `plan/architecture-requirements/data/synchronization-and-audit.md`
- `plan/architecture-requirements/data/README.md` (sync cursor storage, tombstone retention)
