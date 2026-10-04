# Ticket 035 — Implement Canonical Domain Models

- **Category:** Domain / Core
- **Priority:** High
- **Status:** Open

## Context

The canonical domain requirements are in [`plan/architecture-requirements/data/`](../../architecture-requirements/data/README.md). The 48-entity inventory is in [`plan/data-model/`](../../data-model/README.md) with one document per entity under [`entities/`](../../data-model/entities/) and one JSON example per entity under [`examples/entities/`](../../data-model/examples/entities/README.md). Architecture requirements take precedence over the ERD and entity pages when they conflict.
`packages/soar_score_core` currently contains only a placeholder `Contest`, a UUIDv7 `Id`, and contest repository contracts. This ticket completes the core domain types so that ticket 036 can persist them. Core remains pure Dart: no Flutter, database, filesystem, HTTP, or platform-specific dependencies.

### How the model is used

The same domain code runs in two places, and the model must support both:

- **Server** (`soar_score_server`, PostgreSQL): the sole authority. It assigns mutation sequences, enforces installation authority, classifies stale changes, and owns accounts, publication and invitations.
- **Native offline application** (embedded API over SQLite): applies changes locally first, records them as pending mutations, and sends them to the server immediately when connected. It never needs the backend-only entities.
- **Web applications** hold no contest data. They reach everything through the API, so they use API DTOs (`soar_score_api`), never the persistence layer.
  Entities therefore fall into the groups in the [Sync Scope](../../data-model/README.md#sync-scope) table (contest, director, system, issued by the service, derived, backend only). Core models all of them, but the group is part of each model's contract, because it decides who may write the entity and whether it ever reaches an offline installation.

## Scope

Implement domain models for all 48 entities, using the per-entity documents for fields, invariants and relationships. Families, in suggested delivery order:
| Family | Entities |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Sync and audit (first) | `MutationRecord`, `ConflictRecord`, `Tombstone`, `AuditEvent`, `Installation`, `InstallationActivation`, `SyncCursor` |
| Contest and configuration | `Contest`, `ContestConfigurationRevision`, `ContestConfigurationPreset` |
| Discipline (system data) | `DisciplineProfile`, `DisciplineConfigField`, `DisciplineScoreField`, `DisciplineValidation`, `DisciplineFormula`, `DisciplineRule` |
| Landing tables | `LandingTable`, `LandingResult` |
| Participants and roles | `ParticipantProfile`, `ContestParticipation`, `Role`, `ParticipantAccountLink`, `ParticipantDirectoryEntry` |
| Teams and models | `Team`, `TeamMembership`, `ModelCatalog`, `ContestModelLink` |
| Matrix | `MatrixRevision`, `Round`, `RoundGroup`, `MatrixAssignment`, `ReFlight`, `ReFlightParticipant` |
| Scores and reviews | `ScorePlaceholder`, `ScoreAttempt`, `OfficialScore`, `ReviewRequest`, `Invitation` |
| Derived results | `FlightResult`, `ParticipationStanding`, `TeamStanding` |
| Accounts (backend only) | `Account`, `AccountIdentity`, `AccountPublicProfile` |
| Publication (backend only) | `PublicationIdentity`, `PublicationProjection`, `PublicationParticipant`, `DelistRequest` |
Implement enums and value types for the states and options required by those entities and by [contest-options.md](../../data-model/contest-options.md). Do not add persistence-only or UI-only types to the domain layer.
The scoring engine, the draw engine, and the sync protocol are not part of this ticket. This ticket defines the types they consume.

## Design Requirements

- Reuse `Id` for UUIDv7 identity and references. Keep relationships as IDs rather than cyclic object graphs. `ContestParticipation.scoring_uuid` is the one random UUIDv4 and needs its own type.
- Every synchronizable entity carries its contest or owner scope, an integer `revision`, and nothing that depends on the storage engine.
- Define a sync-scope marker for each model (contest, director, system, issued, derived, backend-only) so the data layer and the sync code can decide behaviour from the type instead of from a hard-coded list.
- Model all state dimensions independently. Do not collapse contest lifecycle, scoring access, administration lock, publication, visibility, archive and deletion into one status. Use the vocabulary in [follow-ups.md](../../data-model/follow-ups.md): visibility is `Unlisted` or `Public` (`Delisted` is administrator-only), there is no `PendingDelete` or deletion status, and retirement is `retired_at_round`.
- Preserve immutable score attempts and official score revisions. Calculation outputs (`FlightResult`, `ParticipationStanding`, `TeamStanding`) carry the matrix, configuration, discipline rules and calculation versions they were computed under.
- Preserve the distinction between missing, explicit zero and retired scores, and between drafts or queued local submissions and accepted data.
- Make mutation payloads versioned. A `MutationRecord` names its `entity_type` and carries a schema or protocol version, because offline installations will lag the server.
- Keep private participant data, invitation credentials and director-only audit details distinguishable by type so publication code can exclude them by construction.
- Time values are UTC. Enumerations serialize as the exact text values in the entity documents, so they match the check constraints in ticket 036 and the JSON on the wire.
- Reconcile any conflict between the entity pages and the architecture documents before finalizing a public type, and record the resolution in the relevant documentation and in ticket 036.

## Work Items

- [ ] Check the field inventory of all 48 files under `plan/data-model/entities/` against `plan/data-model/examples/` and the controlling architecture documents. Record discrepancies and their resolution in a short section at the end of this ticket.
- [ ] Add the shared building blocks first: revision, sync-scope marker, UTC timestamp handling, `scoring_uuid` type, versioned payload envelope, and the enum barrel.
- [ ] Implement the families in the order above, one family per PR where practical. Keep one class per file and group files by family under `lib/models/`.
- [ ] Expand `Contest` without losing its existing UUIDv7, UTC, validation, equality and repository behaviour.
- [ ] Add JSON serialization with the repository's `json_annotation` / `json_serializable` convention, with no I/O or backend dependencies. Regenerate checked-in code.
- [ ] Define repository contracts in `soar_score_core` for the entities that need them. Include the contract that makes sync possible: a write goes through one unit of work that stores the entity, bumps its revision and records the `MutationRecord` (and `Tombstone` for deletes) together, plus a separate "apply replicated change" operation used only when pulling from the server. Also define the `SyncStore` contract used by the sync engine and the server acceptor (see ticket 037): outbox reads and outcome updates, cursor reads and writes, replicated-change apply, and conflict and status queries. Contracts only; implementations belong to ticket 036.
- [ ] Export the supported public models and enums from `soar_score_core.dart`.
- [ ] Add focused tests, split by family, for construction, validation, equality, serialization round-trips, independent state dimensions, and representative relationship and provenance fields.
- [ ] Add a round-trip test that loads every JSON file in `plan/data-model/examples/entities/` into its model and back, so the documented examples stay valid.

## Acceptance Criteria

- [ ] Every one of the 48 entities has a domain representation, or a documented architecture-driven resolution explains its alternative representation.
- [ ] Identifiers and references use `Id`; models are immutable and do not embed persistence concerns.
- [ ] State, revision, provenance, privacy, idempotency and sync-scope distinctions from the architecture documents are represented.
- [ ] The repository contracts express the single-unit-of-work write and the separate replicated-change write.
- [ ] Core remains usable without Flutter, database, network or platform APIs.
- [ ] `dart analyze` and `dart test` pass in `packages/soar_score_core`.
- [ ] All JSON examples under `plan/data-model/examples/entities/` round-trip through the models.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md) — core package and existing `Id` and repository contracts.
- Pre-implementation decision tickets that define fields: [010](../pre-implementation/010-scoring-recalculation-invalidation-scope.md) (recalculation scope), [012](../pre-implementation/012-data-score-status-enum.md) (score status values), and [013](../pre-implementation/013-sync-score-edit-conflict.md) to [016](../pre-implementation/016-sync-config-contention.md) (sync conflict handling). If one is still open when its family starts, mark the affected fields as provisional in this ticket rather than guessing.
- Blocks [036-create-drift-schema.md](036-create-drift-schema.md).

## Sources

- [Data model index](../../data-model/README.md), [ERD](../../data-model/ERD.md) and [contest options](../../data-model/contest-options.md)
- [Entity specifications](../../data-model/entities/) and [JSON examples](../../data-model/examples/entities/README.md)
- [Architecture data requirements](../../architecture-requirements/data/README.md)
- [Offline synchronization](../../architecture-requirements/offline-synchronization.md) and [offline usage](../../architecture-requirements/offline-usage.md)
- [Core package guide](../../../packages/soar_score_core/AGENTS.md)
- Existing `packages/soar_score_core/lib/models/id.dart`, `models/contest.dart` and repository contracts

## Discrepancies and decisions

Recorded as the models land. See [035-implementation-plan.md](035-implementation-plan.md) for the full list.
| Area | Finding | Resolution |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Example format | The examples were Markdown files with fenced `json` blocks, not JSON files. | The examples are now one pure JSON file per entity (an array of rows) with a README, so the ticket wording stands. |
| Entity count | `reconciliation-findings.md` said 47 entities; the ERD, catalog and `entities/` have 48. | Fixed to 48. |
| Score representation | The spec says `Decimal`; the ticket forbade floating point. | Owner relaxed the rule (D2): scores use Dart `double`. Revisit if scores disagree across devices or exact ties matter. |
| Equality | 48 classes need value equality. | `equatable` added as a runtime dependency (D1); core `AGENTS.md` updated. |
| Initial revision | `Contest.revision` defaulted to 1 while every other entity defaulted to 0. | Owner: every `revision` starts at 0. `Contest` and `Team` specs updated. `Synchronizable.revision` stays a plain `int`. |
| `Contest.startedAt` | The placeholder field has no counterpart in the entity. | Removed (D3): `Contest` now has `start_date_time` and `end_date_time`. The data package's `contests` table has a column for every `Contest` field; the other tables stay with ticket 036. |
| Sync records and revision | `data-model/README.md` said MutationRecord, ConflictRecord and AuditEvent carry a revision, but their pages have no `revision` column. | Owner: the README was imprecise and these three need no revision. README corrected. They implement `SyncScoped` (scope only), not `Synchronizable`, which keeps `revision`. |
| Sync scope of sync records | MutationRecord, ConflictRecord and Tombstone each belong to either a contest or a director's data; AuditEvent also has a publication-only form. The README lists them under single scopes. | Scope is computed per instance: `contest_id` gives contest, `owner_account_id` gives director. A publication-only AuditEvent is `backendOnly`. Confirm the AuditEvent rule. |
| Payload version | The plan gave `MutationRecord` a `schemaVersion`, but the entity page has only `payload`. | The page wins: `payload` is a plain map. `VersionedPayload` stays available for when a payload version is specified. |
| Entity type | The plan suggested an enum of entity names for `MutationRecord.entity_type`; the page says text. | Kept as text. An enum can be added where a decoder is chosen. |
| Timestamp format | Examples write whole seconds as `2026-10-17T15:10:00Z`; Dart's `toIso8601String` adds `.000`. | `formatUtcTimestamp` drops an all-zero fraction so rows round-trip exactly. |
| Configuration `config` | `ContestConfigurationPreset`'s example `config.core` lacks several options (such as `tiebreaker_enabled`) although a preset holds the "full resolved settings". | `ContestConfig` keeps the maps exactly as written, so both examples round-trip. `CoreOptions` resolves missing options to platform defaults. The preset example could list every option. |
| Row revision on entities | Besides the sync records, ContestConfigurationRevision, MatrixRevision, MatrixAssignment, ScoreAttempt and OfficialScore have no `revision` column. The README Sync Scope note is corrected to list them. | `ContestConfigurationRevision` implements `SyncScoped`. Confirm in the matrix PR that `MatrixAssignment` needs no revision, since assignments can move. |
| Discipline and landing revisions | None of the six discipline entities, `LandingTable` or `LandingResult` has a `revision` column. Profiles change by superseding, and landing tables are immutable. | They implement `SyncScoped` (scope only). Discipline entities are `system`. |
| Landing scope | `LandingTable` is system data or a director's data, depending on its owner. `LandingResult` has no owner or contest of its own. | `LandingTable` computes its scope from `owner_account_id`. `LandingResult` is not `SyncScoped`; it travels with its table. |
| Config field `landing` default | A `landing` config field is documented as holding a landing table id, but the example default value is not an id. | `defaultValue` stays a free-form value so the example round-trips. Revisit when the profile loader checks defaults. |
| Enum constants | `FormulaType` has a value named `final`, and `ConfigFieldType` one named `enum`; both are reserved words in Dart. | Constants are `finalFormula` and `enumeration`; the JSON text is unchanged. |
| ModelCatalog scope | The README lists `ModelCatalog` as director data carrying `owner_account_id`, but the entity page has no such column, calls the catalog "shared across contests" and visible to all users, and names its parent "System or Contest". | Modeled as `system` data with no owner, following the entity page. Confirm, or add an owner column to the page if directors keep their own catalogs. |
| Participation default role | `ContestParticipation.role_id` defaults to "System Pilot role", but the system role ids are not fixed by the documents. | `roleId` is required in the class; the default is applied where participations are created. |
| Participant privacy marker | The plan puts a `PrivateData` marker on `ParticipantProfile`. | Deferred to the plan PR that adds the privacy markers; `ParticipantProfile` is `director` scoped now. |
| Cross-row rules | Unique names, one participation per profile, one team per participation and unique participant numbers span rows. | Left to the repository layer; the classes only check their own fields. |
