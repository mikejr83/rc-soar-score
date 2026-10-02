# Ticket 035 — Implement Canonical Domain Models

- **Category:** Domain / Core
- **Priority:** High
- **Status:** Open

## Context

The canonical domain requirements are in [`plan/architecture-requirements/data/`](../../architecture-requirements/data/README.md), and the 31-entity target inventory is in [`plan/data-model/`](../../data-model/README.md). This ticket replaces the earlier draft, which contained additional and differently named concepts not present in the ERD. Architecture requirements take precedence over the ERD and entity pages when they conflict.

`packages/soar_score_core` currently contains only a placeholder `Contest`, a UUIDv7 `Id`, and contest repository contracts. Complete the core domain types before implementing their persistence in ticket 036. Core remains pure Dart: no Flutter, database, filesystem, HTTP, or platform-specific dependencies. Use immutable models and the repository's JSON serialization conventions.

## Scope

Implement domain models for the ERD entities, using the per-entity documents for fields, invariants, and relationships:

- Identity and participation: `Account`, `Contest`, `ParticipantProfile`, `ParticipantAccountLink`, `ContestParticipation`, `Role`.
- Teams and models: `Team`, `TeamMembership`, `ModelCatalog`, `ContestModelLink`.
- Discipline and configuration: `DisciplineProfile`, `LandingTable`, `LandingResult`, `RoundConfig`, `ContestConfigurationRevision`.
- Matrix and assignments: `MatrixRevision`, `MatrixAssignment`, `ReFlight`.
- Scores and reviews: `ScorePlaceholder`, `ScoreAttempt`, `OfficialScore`, `ScoreCalculationResult`, `ReviewRequest`.
- Publication: `PublicationIdentity`, `PublicationProjection`, `Invitation`.
- Synchronization and audit: `SyncCursor`, `MutationRecord`, `ConflictRecord`, `Tombstone`, `AuditEvent`.

Implement enums/value types for the states and options required by those entities and the architecture specifications. Do not add persistence-only or UI-only types to the domain layer.

## Design Requirements

- Reuse `Id` for UUIDv7 identity and references. Keep relationships as IDs rather than cyclic object graphs.
- Model all state dimensions independently; do not collapse contest lifecycle, scoring access, administration lock, publication, visibility, archive, or deletion state into one status.
- Preserve immutable accepted score attempts and official score revisions; represent calculation outputs with their configuration/matrix/calculation provenance.
- Represent draft/queued data separately from accepted data. Preserve distinction between missing, explicit zero, and retired score states.
- Preserve revision, idempotency, actor/authority, client/server time, conflict, tombstone, and audit information required by the architecture.
- Keep private participant data, invitation credentials, and director-only audit details distinguishable so publication code can exclude them.
- Reconcile any conflict or missing concept between the ERD and architecture requirements in the model docs before adding a new public entity. Record the resolution in the relevant documentation and ticket 036.

## Work Items

- [ ] Confirm the canonical entity/field inventory against all 31 files under `plan/data-model/entities/` and the controlling architecture requirements; resolve discrepancies before finalizing public types.
- [ ] Implement immutable models and required value/enumerated types in `packages/soar_score_core/lib/` using the established folder and naming conventions.
- [ ] Expand `Contest` without losing its existing UUIDv7, UTC, validation, equality, and repository behavior.
- [ ] Add JSON serialization/deserialization using the repository's `json_annotation` / `json_serializable` convention, without introducing I/O or backend dependencies.
- [ ] Export the supported public models and enums from `soar_score_core.dart` and the enum barrel.
- [ ] Add focused tests for construction, validation, equality, serialization round-trips, independent state dimensions, and representative relationship/provenance fields.
- [ ] Regenerate any checked-in serialization code.

## Acceptance Criteria

- [ ] Every ERD entity has a corresponding domain representation, or a documented architecture-driven resolution explains its alternative representation.
- [ ] UUIDv7 identifiers and references use `Id`; models are immutable and do not embed persistence concerns.
- [ ] Required state, revision, provenance, privacy, and idempotency distinctions from architecture documents are represented.
- [ ] Core remains usable without Flutter, database, network, or platform APIs.
- [ ] `dart analyze` and `dart test` pass in `packages/soar_score_core`.
- [ ] Serialization round-trip tests pass for representative entities, including nested JSON-shaped configuration/content.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md) — core package and existing `Id`/repository contracts.
- [036-create-drift-schema.md](036-create-drift-schema.md) — depends on the finalized core model contracts.

## Sources

- [Data model index](../../data-model/README.md) and [ERD](../../data-model/ERD.md)
- [Entity specifications](../../data-model/entities/)
- [Architecture data requirements](../../architecture-requirements/data/README.md)
- [Core package guide](../../../packages/soar_score_core/AGENTS.md)
- Existing `packages/soar_score_core/lib/models/id.dart`, `models/contest.dart`, and repository contracts
