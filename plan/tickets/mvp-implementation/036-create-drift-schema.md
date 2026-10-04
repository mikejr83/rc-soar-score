# Ticket 036 — Implement the Drift Schema for the 48-Entity Model

- **Category:** Data / Persistence
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_data` is one Drift schema and repository layer. The native offline application opens it against SQLite, and the server opens it against PostgreSQL through `drift_postgres`. The executor is chosen at database construction, so tables, migrations and repositories are shared.

The current database is schema version 1 and contains only `Contests(id, name, started_at)`. `onUpgrade` currently rejects upgrades. This ticket persists the 48 entities in [`plan/data-model/`](../../data-model/README.md), using the domain contracts from ticket 035. Architecture requirements are authoritative over the ERD and entity documents when they conflict.

### Storage rules

- **Server:** PostgreSQL holds every entity.
- **Native offline application:** SQLite holds a local copy of the contest data, director data and system data the director's installation needs. It never holds the backend-only group.
- **Web applications:** hold no contest data and never use this package. Browser IndexedDB is limited to preferences and front-end functionality, and is out of scope here.

## Scope

All 48 entities, grouped by the [Sync Scope](../../data-model/README.md#sync-scope) table. The groups are table groups in code, so each executor registers only what it needs:

| Table group           | Entities                                                                                                                                                                                                                                                                                                                                | Registered by     |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| Contest data          | `Contest`, `ContestConfigurationRevision`, `ContestParticipation`, `Team`, `TeamMembership`, `ContestModelLink`, `MatrixRevision`, `Round`, `RoundGroup`, `MatrixAssignment`, `ReFlight`, `ReFlightParticipant`, `ScorePlaceholder`, `ScoreAttempt`, `OfficialScore`, `ReviewRequest`, `MutationRecord`, `ConflictRecord`, `AuditEvent` | Server and native |
| Director data         | `ParticipantProfile`, `ModelCatalog`, `ContestConfigurationPreset`, director-owned `Role`, `LandingTable` and `LandingResult`, and `Tombstone`                                                                                                                                                                                          | Server and native |
| System data           | `DisciplineProfile`, `DisciplineConfigField`, `DisciplineScoreField`, `DisciplineValidation`, `DisciplineFormula`, `DisciplineRule`, system `Role`, system `LandingTable` and `LandingResult`                                                                                                                                           | Server and native |
| Issued by the service | `Invitation`                                                                                                                                                                                                                                                                                                                            | Server and native |
| Derived               | `FlightResult`, `ParticipationStanding`, `TeamStanding`                                                                                                                                                                                                                                                                                 | Server and native |
| Backend only          | `Account`, `AccountIdentity`, `AccountPublicProfile`, `ParticipantAccountLink`, `ParticipantDirectoryEntry`, `PublicationIdentity`, `PublicationProjection`, `PublicationParticipant`, `DelistRequest`, `Installation`, `InstallationActivation`, `SyncCursor`                                                                          | Server only       |

A local accountless contest has no remote account, so native tables that reference an account must tolerate the local account kind defined in the account documents. The native installation also keeps its own copy of its sync position (it advances the cursor only after durably storing the returned changes), while `SyncCursor` itself is server-only. Decide whether that local position is a client-only table or a local variant of `SyncCursor`, and record the decision. Check each foreign key from a contest or director table into the backend-only group and decide whether it is enforced on the server only or stored as a plain identifier on the native side. Record each decision in this ticket.

## Design Requirements

- Keep the schema and repositories in `packages/soar_score_data`. Register tables on `SoarScoreDatabase` by group, and support both configured executors.
- **One portable type mapping**, written down in this ticket and in the data-model README before any DDL is merged. Drift table code is shared, so use types that behave the same on SQLite and PostgreSQL:
  - UUIDv7 and UUIDv4 as text.
  - UTC timestamps as ISO 8601 text (as the current schema does), or as integer epoch values if range comparison requires it. Pick one and apply it everywhere.
  - Enumerations as text with check constraints using the exact values in the entity documents.
  - JSON-shaped content (`payload`, resolved configuration, delivery outcomes) as text holding JSON.
  - `bigint` sequences as integers. SQLite integers are 64-bit, which is sufficient.
  - Scores and derived points as double-precision reals (SQLite `REAL`, PostgreSQL `double precision`), matching the plain Dart `double` in the core models (decision D2, ticket 035). Identical results on both backends must be shown by the shared test suite; if that fails, revisit the decision with the note in the implementation plan.
- Document any dialect-specific features. Partial unique indexes, such as "one open `InstallationActivation` per contest", need hand-written SQL in the migration; keep them in one place and test them on both backends.
- Define foreign keys, indexes, natural and composite uniqueness, and idempotency constraints from the entity and architecture invariants, including `(contest_id, client_mutation_id)` and `(owner_account_id, client_mutation_id)` on `MutationRecord`. Avoid blanket cascade deletes: preserve immutable score, publication, synchronization and audit history as required. A contest deletion removes the director's contest data and leaves any publication in place.
- `ModelCatalog` is director-owned: `owner_account_id` is required and uniqueness is (`owner_account_id`, `name`, `manufacturer`), so two directors can keep the same model. It belongs to the director data group and syncs through the director stream.
- **Unit of work:** implement the write path defined in ticket 035. One transaction stores the entity, increments its `revision`, writes the `MutationRecord` as `Pending` on a client, and writes a `Tombstone` on delete. Repositories must not write contest or director data any other way.
  - `MatrixAssignment` has no `revision`. Moving an assignment adds a new `Moved` row and writes `superseded_by_assignment_id` on the old row exactly once; design how the unit of work performs that single update (it is not a general update path) and records its `MutationRecord`.
- **Replicated writes:** implement the separate "apply replicated change" path used when a client pulls from the server. It preserves the server revision and sequence, does not create a new pending mutation, and is rejected for derived data, which is recomputed instead.
- Keep private identity data, invitation credentials and director-only audit data out of public projections by construction of the persistence and read boundaries.
- Preserve append-only score attempts and revisioned official, calculation and publication history. Derived results retain their input and configuration provenance.
- **Versioning:** record the schema version in the database and expose it to the sync handshake. Migrations must be written so that an installation that is several versions behind can be upgraded in sequence, or is told to update before it syncs.
- Do not implement API routes, the sync protocol itself, scoring workflows, UI, or browser storage in this ticket.

## Work Items

- [ ] Reconcile every entity's fields and relationships with the architecture documents. Document the portable type mapping, the foreign keys that cross into the backend-only group, and any required model or ERD corrections. Update `plan/data-model/README.md` Physical Design Decisions to match.
- [ ] Add Drift tables, foreign keys, indexes and unique constraints per table group in `packages/soar_score_data/lib/`, one table per file, grouped by folder.
- [ ] Expand `Contests` to the full domain shape while keeping the current repository behaviour compatible with ticket 035.
- [ ] Register table groups so that the server executor registers all groups and the native executor omits the backend-only group. Cover both with tests.
- [ ] Advance `SoarScoreDatabase.schemaVersion` from 1 to 2 and implement a v1-to-v2 migration that preserves existing contest rows and supplies defaults for newly required columns. Fresh databases create the latest schema directly.
- [ ] Implement the unit of work and the replicated-change path in the data layer, and implement the `SyncStore` contract from ticket 035 on top of them so `soar_score_sync` (ticket 037) never touches drift directly.
- [ ] Add repositories and mappers for the entities needed by the current core contracts, in families matching ticket 035. Keep database access in this package and enforce multi-row invariants transactionally.
- [ ] Regenerate checked-in Drift code with `build_runner`.
- [ ] Add schema and constraint tests, and CRUD and round-trip tests, for every table group. Include v1 upgrade and fresh-database cases.
- [ ] Run the same test suite against SQLite and against a configured PostgreSQL database. Report PostgreSQL as unverified if no database is available; skipped tests are not a pass.
- [ ] Load each JSON example under `plan/data-model/examples/entities/` through the repositories on both backends to confirm they persist and read back unchanged.

## Acceptance Criteria

- [ ] All 48 entities are persisted in the correct table group, or a documented resolution explains any deliberate alternative.
- [ ] The native executor creates no backend-only tables. The server creates all groups.
- [ ] SQLite and PostgreSQL give equivalent identifier, timestamp, decimal, enumeration, uniqueness, relationship and revision behaviour, shown by the shared test suite.
- [ ] Every contest or director write produces exactly one revision bump and one `MutationRecord` or `Tombstone` in the same transaction. A replicated write produces none.
- [ ] Migration from v1 preserves existing contest data, and creation of the latest schema works on a fresh database.
- [ ] Foreign keys, uniqueness and indexes enforce the documented invariants without deleting required immutable history.
- [ ] `dart run build_runner build`, `dart analyze` and `dart test` pass in `packages/soar_score_data`.
- [ ] SQLite tests pass; PostgreSQL tests pass when run against a configured instance.

## Dependencies

- [007-scaffold-data-package.md](007-scaffold-data-package.md) — original SQLite data package scaffold (since merged into the unified `soar_score_data`).
- [035-create-data-models.md](035-create-data-models.md) — finalized domain models, repository contracts and serialization.
- [016-scaffold-data-postres-package.md](016-scaffold-data-postres-package.md) — historical PostgreSQL setup decisions only; its package layout is superseded by the unified data package.
- [037-sync-protocol-and-engine.md](037-sync-protocol-and-engine.md) — the synchronization protocol, server service and client engine. This ticket provides the storage it relies on but does not implement it.

## Sources

- [Data model index](../../data-model/README.md), [ERD](../../data-model/ERD.md) and [contest options](../../data-model/contest-options.md)
- [Entity specifications](../../data-model/entities/) and [JSON examples](../../data-model/examples/entities/README.md)
- [Architecture data requirements](../../architecture-requirements/data/README.md)
- [Offline synchronization](../../architecture-requirements/offline-synchronization.md) and [offline usage](../../architecture-requirements/offline-usage.md)
- Current `packages/soar_score_data/lib/contests_table.dart`, `database.dart`, `migrate.dart` and `repositories/`
- `packages/soar_score_data/test/` for current SQLite and PostgreSQL test conventions
