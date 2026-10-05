# Ticket 036 — Implement the Drift Schema for the 48-Entity Model

- **Category:** Data / Persistence
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_data` is one Drift schema and repository layer. The native offline application opens it against SQLite, and the server opens it against PostgreSQL through `drift_postgres`. The executor is chosen at database construction, so tables, migrations and repositories are shared.

The current database is schema version 1 and contains only the `contests` table, whose columns already match the full `Contest` model. That table was changed in place (PR 58) with no upgrade path, because nothing had been released; `onUpgrade` still rejects upgrades. This ticket persists the 48 entities in [`plan/data-model/`](../../data-model/README.md), using the domain contracts from ticket 035. Architecture requirements are authoritative over the ERD and entity documents when they conflict.

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

## Decisions

- **Timestamps:** UTC ISO 8601 text with a `Z` suffix on both backends (the contests table already does this). The data-model README previously said "timestamps with a time zone"; it now matches.
- **Enumerations:** text with a check constraint listing the exact values. The lists live in `packages/soar_score_data/lib/schema/enum_values.dart`, and a test compares each with the `@JsonValue` texts of the core enum.
- **Table groups:** every table has a group in `tableGroupByName`. A `DatabaseProfile` (`native` or `server`) chooses which groups the database creates; a test fails for any table without a group.
- **Local sync position:** the client-only table `local_sync_positions`, not a local copy of `SyncCursor`, which stays server-only. It sits in a new `clientOnly` table group that the native profile creates and the server does not.
- **History tables:** `mutation_records`, `conflict_records`, `tombstones` and `audit_events` have no foreign keys, because a record must outlive the entity and contest it names. A mutation record has exactly one of `contest_id` and `owner_account_id`, its client mutation id is unique within that scope, and a sequence belongs only to an accepted mutation.
- **Entity rows as JSON:** columns are named like the JSON keys, so one `TableMapper` reads and writes any entity table through the model's own `toJson` and `fromJson`. A new entity type needs a table and one registered `EntityStore`.
- **Mutation payload:** a `VersionedPayload` (version 1) whose data is `{operation: save, entity: {...}}` or `{operation: delete}`. Ticket 037 owns the wire format and may extend it.
- **Revision on save:** a new entity keeps the revision it was built with (0 by default). A stored entity must be saved at its stored revision, or the unit of work throws `StaleRevisionError`, and the stored revision goes up by one.
- **Foreign keys:** a table references its parent by a real foreign key, parents created first. Only `contest_id` cascades on delete, so deleting a contest removes the director's contest data in one statement, with no tombstone for each child (the contest's own tombstone and mutation tell other installations to do the same). Every other key is a plain `NO ACTION`: a parent with children cannot be deleted. SQLite is opened with `PRAGMA foreign_keys = ON` so both backends enforce them.
- **Keys into the backend-only group:** `owner_account_id`, `created_by` and `updated_by` are plain identifiers with no foreign key, because accounts are never on an installation. Rows keep working with the local account kind.
- **Expression and partial indexes:** the case-insensitive and "only one" rules (role names, the single Pilot role, preset names, model names without a manufacturer, one primary formula per profile) are unique indexes in `lib/schema/custom_indexes.dart`, created by the migration and tested.
- **Shared tables:** `Role`, `LandingTable` and `LandingResult` keep system and director rows in one table, told apart by `owner_account_id`.
- **Both dialects:** `packages/soar_score_data/build.yaml` generates SQL for SQLite and PostgreSQL. Without it Drift wrote SQLite-only column checks (`CHECK (flag IN (0, 1))` on a boolean) that PostgreSQL rejects, so the schema could not be created on the server at all.
- **Placeholders:** hand-written SQL uses `?` and goes through `portableSql`, which rewrites it to `$1`, `$2` for PostgreSQL.
- **Shared test suite:** `test/support/backends.dart` runs each suite on SQLite and, when `POSTGRES_PASSWORD` is set, on PostgreSQL in a database created and dropped per test. Without a server the PostgreSQL group is reported as skipped, which is not a pass. The sync position tests are SQLite only, because that table is client only.
- **Matrix, score and result tables:** 13 tables, one per entity (`matrix_revisions`, `rounds`, `round_groups`, `re_flights`, `matrix_assignments`, `re_flight_participants`, `score_placeholders`, `score_attempts`, `official_scores`, `review_requests`, and the derived `flight_results`, `participation_standings` and `team_standings`). The derived tables are in the `derived` group and only the calculator writes them; the applier already refuses them.
- **Append-only entities:** `MatrixRevision`, `MatrixAssignment`, `ScoreAttempt` and `OfficialScore` implement the core `AppendOnly` interface and are stored with `WriteContext.append`, which throws `AlreadyStoredError` for an id that is stored. `ContestConfigurationRevision` is append-only too and uses the same write.
- **Moving an assignment:** `WriteContext.moveAssignment` stores the new `Moved` row and sets `superseded_by_assignment_id` on its source in one transaction, with one `MutationRecord` whose payload is `{operation: save, entity, supersedes}`. The update is guarded (`WHERE superseded_by_assignment_id IS NULL`), so a second move throws `AlreadySupersededError`. The marker's foreign key is deferred, because the old row must leave the live-assignment unique index before the new row enters it. A replicated move arrives as two changes, the new row and the old row with its marker.
- **Natural keys:** `(contest_id, client_mutation_id)` is unique on score attempts (the architecture data README names this key; the entity document says globally unique). The conditional rules of the entity documents (one live round ordinal, one pilot per credited round, one lane per group, one open review request, one finalized successor per revision) are partial unique indexes in `custom_indexes.dart`; the type rules of an assignment and the lock and exclusion rules are table checks.
- **Composite keys not enforced:** the documents ask for composite foreign keys that make a child's `contest_id` equal its parent's, and tie a placeholder to its assignment's participation. The tables use plain foreign keys; the model classes and the unit of work set these fields together. Revisit if a second writer appears.
- **Backend-only and invitation tables:** 13 tables: `accounts`, `account_identities`, `account_public_profiles`, `participant_account_links`, `participant_directory_entries`, `installations`, `installation_activations`, `sync_cursors`, `publication_identities`, `publication_projections`, `publication_participants` and `delist_requests` in the backend-only group, and `invitations` in the issued group. With them all 48 entities have a table, and a test fails if an example file is not loaded.
- **Keys among backend-only tables:** real foreign keys, with accounts, publications and installations as parents. Plain ids where the target can disappear or sits outside the group: `installation_activations.contest_id` and `sync_cursors.contest_id` (the rows are never deleted, so a key would block deleting a contest), `participant_account_links.participant_profile_id` (director data on the device), `publication_participants.source_participation_id` (the document says it is not a key) and `publication_identities.current_projection_id` (it and the projection's `publication_id` point at each other). `publication_identities.contest_id` is `ON DELETE SET NULL`, so a contest deletion leaves the publication; `invitations.contest_id` cascades.
- **Rules from the documents:** account email is stored in lowercase and unique, and exactly one account is `deleted`; an identity is unique by issuer and subject; a profile has at most one confirmed link; a contest has one open activation; a publication has one pending delist request; a participation has one active invitation; a sync cursor has exactly one of `contest_id` and `owner_account_id`. These are unique keys, partial unique indexes and checks.
- **Invitation credential:** the `invitations` store writes `toSyncJson`, because `toJson` leaves the protected credential out. The column holds the protected form only, and nothing in this package ever sees the raw credential.
- **History entities have stores:** `AuditEvent`, `ConflictRecord`, `MutationRecord` and `Tombstone` are registered too, so their examples load like the others. The unit of work still writes them only as part of a mutation.
- **Configuration revisions:** `ContestConfigurationRevision` is now an `AppendOnly` entity and is stored with `WriteContext.append`.
- **Repository contract:** `ContestRepository.save` and `delete` take `MutationMetadata` and run through the unit of work, so every write names who made it.

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
- [ ] Keep `Contests` as it is (already the full `Contest` shape) and keep the current repository behaviour compatible with ticket 035.
- [ ] Register table groups so that the server executor registers all groups and the native executor omits the backend-only group. Cover both with tests.
- [ ] Create the new tables in schema version 1 while the app is unreleased, with no upgrade path (as for `contests`). Once a version ships, advance `schemaVersion` and write in-sequence migrations. Fresh databases create the latest schema directly.
- [ ] Implement the unit of work and the replicated-change path in the data layer, and implement the `SyncStore` contract from ticket 035 on top of them so `soar_score_sync` (ticket 037) never touches drift directly.
- [ ] Add repositories and mappers for the entities needed by the current core contracts, in families matching ticket 035. Keep database access in this package and enforce multi-row invariants transactionally.
- [ ] Regenerate checked-in Drift code with `build_runner`.
- [ ] Add schema and constraint tests, and CRUD and round-trip tests, for every table group. Include fresh-database creation; add upgrade cases once a version ships.
- [ ] Run the same test suite against SQLite and against a configured PostgreSQL database. Report PostgreSQL as unverified if no database is available; skipped tests are not a pass.
- [ ] Load each JSON example under `plan/data-model/examples/entities/` through the repositories on both backends to confirm they persist and read back unchanged.

## Acceptance Criteria

- [ ] All 48 entities are persisted in the correct table group, or a documented resolution explains any deliberate alternative.
- [ ] The native executor creates no backend-only tables. The server creates all groups.
- [ ] SQLite and PostgreSQL give equivalent identifier, timestamp, decimal, enumeration, uniqueness, relationship and revision behaviour, shown by the shared test suite.
- [ ] Every contest or director write produces exactly one revision bump and one `MutationRecord` or `Tombstone` in the same transaction. A replicated write produces none.
- [ ] Creation of the latest schema works on a fresh database. Upgrade migrations are required only after a version ships.
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
