# Ticket 036 — Implement the ERD Drift Schema

- **Category:** Data / Persistence
- **Priority:** High
- **Status:** Open

## Context

This ticket replaces the earlier draft, which described extra entities and targeted package names that no longer exist. The current persistence package is `packages/soar_score_data`: one Drift schema and repository layer support native SQLite for local/offline use and PostgreSQL for the server through `QueryExecutor`.

The current database is schema version 1 and contains only `Contests(id, name, started_at)`. `onUpgrade` currently rejects upgrades. Implement the ERD persistence after ticket 035 establishes the domain contracts. Architecture requirements are authoritative over the ERD/entity documentation when they conflict.

MVP web applications use the API for data access. Browser IndexedDB persistence is out of scope. SQLite remains the local/offline store and PostgreSQL remains the server store.

## Scope

Implement persistence for the 31 entities in `plan/data-model/ERD.md` and `plan/data-model/entities/`:

`Account`, `Contest`, `ParticipantProfile`, `ParticipantAccountLink`, `ContestParticipation`, `Role`, `Team`, `TeamMembership`, `ModelCatalog`, `ContestModelLink`, `DisciplineProfile`, `LandingTable`, `LandingResult`, `RoundConfig`, `ContestConfigurationRevision`, `MatrixRevision`, `MatrixAssignment`, `ReFlight`, `ScorePlaceholder`, `ScoreAttempt`, `OfficialScore`, `ScoreCalculationResult`, `PublicationIdentity`, `PublicationProjection`, `SyncCursor`, `MutationRecord`, `ConflictRecord`, `Tombstone`, `Invitation`, `ReviewRequest`, and `AuditEvent`.

Before finalizing DDL, map every field and relationship to the canonical architecture documents. Record decisions for any mismatch, including concepts required by architecture but absent from the ERD. Do not silently add entities from the superseded ticket draft.

## Design Requirements

- Keep the schema and repositories in `packages/soar_score_data`; register all Drift tables on the existing `SoarScoreDatabase` and support both configured executors.
- Map UUIDv7 IDs, UTC timestamps, enums, JSON-shaped content, nullability, and numeric precision consistently across SQLite and PostgreSQL. Document any dialect-specific physical mapping and test equivalent behavior on both backends.
- Define foreign keys, indexes, natural/composite uniqueness, and idempotency constraints from the entity and architecture invariants. Avoid blanket cascade deletes: preserve immutable score, publication, synchronization, and audit history as required.
- Keep private identity data, invitation credentials, and director-only audit data out of public projections by construction of the persistence/read boundaries.
- Preserve append-only score attempts and revisioned official/calculation/publication history; derived results must retain their input/configuration provenance.
- Do not implement API routes, synchronization behavior, scoring workflows, UI, or browser storage in this ticket.

## Work Items

- [ ] Reconcile the ERD and all per-entity definitions with architecture requirements; document the resolved physical mapping and any required model/ERD corrections.
- [ ] Add Drift tables, foreign keys, indexes, and unique constraints for the approved entity inventory in `packages/soar_score_data/lib/`.
- [ ] Expand `Contests` to the approved full domain shape while keeping the current public repository behavior compatible with ticket 035.
- [ ] Register all tables and advance `SoarScoreDatabase.schemaVersion` from 1 to 2.
- [ ] Implement a version-1-to-version-2 migration that preserves existing contest rows and supplies valid defaults for newly required columns. Fresh databases must create the latest schema directly.
- [ ] Add domain repositories/mappers for the entities required by current core contracts; keep database access in this package and transactionally enforce multi-row invariants.
- [ ] Regenerate checked-in Drift code with `build_runner`.
- [ ] Add schema/constraint tests and representative CRUD/round-trip tests for every table family. Include v1 upgrade and fresh-database cases.
- [ ] Run the PostgreSQL integration suite against a configured test database; report it as unverified if no database is available, rather than treating skipped tests as a pass.

## Acceptance Criteria

- [ ] All approved ERD entities and architecture-required fields are persisted, or a documented resolution explains any deliberate alternative.
- [ ] SQLite and PostgreSQL exhibit equivalent identifier, timestamp, uniqueness, relationship, and revision semantics.
- [ ] Migration from v1 preserves existing contest data; latest-schema creation works on a fresh database.
- [ ] Foreign keys, uniqueness, and indexes enforce the documented invariants without deleting required immutable history.
- [ ] Drift generation, `dart analyze`, and `dart test` pass in `packages/soar_score_data`.
- [ ] SQLite schema/migration tests pass; PostgreSQL integration tests pass when run against a configured instance.

## Dependencies

- [007-scaffold-data-package.md](007-scaffold-data-package.md) — existing unified Drift database infrastructure.
- [035-create-data-models.md](035-create-data-models.md) — finalized domain models and serialization contracts.
- [016-scaffold-data-postres-package.md](016-scaffold-data-postres-package.md) — historical PostgreSQL setup decisions only; its package layout is superseded by the unified data package.

## Sources

- [Data model index](../../data-model/README.md) and [ERD](../../data-model/ERD.md)
- [Entity specifications](../../data-model/entities/)
- [Architecture data requirements](../../architecture-requirements/data/README.md)
- Current `packages/soar_score_data/lib/contests_table.dart`, `database.dart`, `migrate.dart`, and `repositories/`
- `packages/soar_score_data/test/` for current SQLite and PostgreSQL test conventions
