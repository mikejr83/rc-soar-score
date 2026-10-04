# Ticket 035 — Implement Canonical Domain Models

- **Category:** Domain / Core
- **Priority:** High
- **Status:** In-Review

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
- `ModelCatalog` is director-owned and carries a required `owner_account_id`; it is private to its director and is not shared across directors in the first release.
- Model all state dimensions independently. Do not collapse contest lifecycle, scoring access, administration lock, publication, visibility, archive and deletion into one status. Use the vocabulary in [follow-ups.md](../../data-model/follow-ups.md): visibility is `Unlisted` or `Public` (`Delisted` is administrator-only), there is no `PendingDelete` or deletion status, and retirement is `retired_at_round`.
- Preserve immutable score attempts and official score revisions. Calculation outputs (`FlightResult`, `ParticipationStanding`, `TeamStanding`) carry the matrix, configuration, discipline rules and calculation versions they were computed under.
- Preserve the distinction between missing, explicit zero and retired scores, and between drafts or queued local submissions and accepted data.
- Make mutation payloads versioned. A `MutationRecord` names its `entity_type` and carries a schema or protocol version, because offline installations will lag the server.
- Keep private participant data, invitation credentials and director-only audit details distinguishable by type so publication code can exclude them by construction.
- Time values are UTC. Enumerations serialize as the exact text values in the entity documents, so they match the check constraints in ticket 036 and the JSON on the wire.
- Reconcile any conflict between the entity pages and the architecture documents before finalizing a public type, and record the resolution in the relevant documentation and in ticket 036.

## Work Items

- [x] Check the field inventory of all 48 files under `plan/data-model/entities/` against `plan/data-model/examples/` and the controlling architecture documents. Record discrepancies and their resolution in a short section at the end of this ticket.
- [x] Add the shared building blocks first: revision, sync-scope marker, UTC timestamp handling, `scoring_uuid` type, versioned payload envelope, and the enum barrel.
- [x] Implement the families in the order above, one family per PR where practical. Keep one class per file and group files by family under `lib/models/`.
- [x] Expand `Contest` without losing its existing UUIDv7, UTC, validation, equality and repository behaviour.
- [x] Add JSON serialization with the repository's `json_annotation` / `json_serializable` convention, with no I/O or backend dependencies. Regenerate checked-in code.
- [x] Define repository contracts in `soar_score_core` for the entities that need them. Include the contract that makes sync possible: a write goes through one unit of work that stores the entity, bumps its revision and records the `MutationRecord` (and `Tombstone` for deletes) together, plus a separate "apply replicated change" operation used only when pulling from the server. Also define the `SyncStore` contract used by the sync engine and the server acceptor (see ticket 037): outbox reads and outcome updates, cursor reads and writes, replicated-change apply, and conflict and status queries. Contracts only; implementations belong to ticket 036.
- [x] Export the supported public models and enums from `soar_score_core.dart`.
- [x] Add focused tests, split by family, for construction, validation, equality, serialization round-trips, independent state dimensions, and representative relationship and provenance fields.
- [x] Add a round-trip test that loads every JSON file in `plan/data-model/examples/entities/` into its model and back, so the documented examples stay valid.

## Acceptance Criteria

- [x] Every one of the 48 entities has a domain representation, or a documented architecture-driven resolution explains its alternative representation.
- [x] Identifiers and references use `Id`; models are immutable and do not embed persistence concerns.
- [x] State, revision, provenance, privacy, idempotency and sync-scope distinctions from the architecture documents are represented.
- [x] The repository contracts express the single-unit-of-work write and the separate replicated-change write.
- [x] Core remains usable without Flutter, database, network or platform APIs.
- [x] `dart analyze` and `dart test` pass in `packages/soar_score_core`.
- [x] All JSON examples under `plan/data-model/examples/entities/` round-trip through the models.

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
| ModelCatalog scope | The README listed `ModelCatalog` as director data, but the entity page had no owner column and called the catalog shared. | Owner fixed the documents: `ModelCatalog` is director-owned with a required `owner_account_id`. The class carries it and is `director` scoped. |
| Participation default role | `ContestParticipation.role_id` defaults to "System Pilot role", but the system role ids are not fixed by the documents. | `roleId` is required in the class; the default is applied where participations are created. |
| Participant privacy marker | The plan puts a `PrivateData` marker on `ParticipantProfile`. | Deferred to the plan PR that adds the privacy markers; `ParticipantProfile` is `director` scoped now. |
| Cross-row rules | Unique names, one participation per profile, one team per participation and unique participant numbers span rows. | Left to the repository layer; the classes only check their own fields. |
| MatrixAssignment revision | Memory flagged that assignments can move, so a revision might be needed. The page and example have no `revision`; a move adds a `Moved` row and writes only `superseded_by_assignment_id`, once. | Confirmed: `MatrixAssignment` implements `SyncScoped` with no revision. `MatrixRevision` has none either. Confirm how the unit of work writes the one-time `superseded_by_assignment_id` update when ticket 036 designs it. |
| Matrix scope | `MatrixRevision`, `Round`, `RoundGroup`, `MatrixAssignment`, `ReFlight` and `ReFlightParticipant` all carry `contest_id`. | All are `contest` scoped. `Round`, `RoundGroup`, `ReFlight` and `ReFlightParticipant` are `Synchronizable` with a row revision. |
| Matrix invariants | Many rules span rows (unique rounds and lanes, one current assignment per round, team protection, group capacity, current-round tests). | Only single-row rules are in the classes: type-specific assignment fields, status-dependent re-flight fields, group lock fields, seed range and round ranges. The rest belong with the matrix logic and repositories. |
| Re-flight and move credit | A `Moved` or `Reflight` row copies `credited_round_id` and `flight_sequence` from its source. | Not checkable from one row, so left to the code that creates the row. |
| Score entity revisions | `ScorePlaceholder` and `ReviewRequest` have a row `revision`. `ScoreAttempt`, `OfficialScore` and `Invitation` have none; `OfficialScore` has `score_revision`, which is a different counter. | `ScorePlaceholder` and `ReviewRequest` are `Synchronizable`. The other three are `SyncScoped`. `Invitation` is `issued` scoped, the rest `contest`. |
| Invitation credential in JSON | The plan keeps the protected credential out of `Invitation.toJson` but the example row includes it. | `toJson` omits `protected_credential`; `toSyncJson` carries it for the sync and API path. `fromJson` requires it. The example harness round-trips through `toSyncJson`. `ProtectedCredential.toString` is redacted. |
| Invitation state and dates | `revoked_at` is "non-null if state is Revoked" but nothing says the reverse, and an `Expired` or `Replaced` invitation may or may not have been revoked first. | Only the stated direction is enforced. |
| Review decision fields | The page says the decision fields are null while `Submitted` and sets the resulting attempt on approval, but not what `UnderReview` or `Superseded` hold. | A decision actor and time are set together. `Approved` and `Rejected` need them, `Submitted` has none, and `resulting_attempt_id` is set exactly when `Approved`. |
| Penalty components | `flight_penalty` and `cumulative_penalty` live inside free-form component maps. | A shared check requires non-negative integers or null. A `ScoreAttempt` sets `cumulative_penalty` only under director authority, and a `ReviewRequest` cannot include it. The remaining component checks need the discipline profile and wait for the scoring engine. |
| Privacy marker | The plan puts a `PrivateData` marker on `Invitation`, as on `ParticipantProfile`. | Both wait for the privacy test in plan PR 10. |
| Derived results and decimals | The `FlightResult`, `ParticipationStanding` and `TeamStanding` pages say values are exact decimals, never floating point. | Per decision D2 the fields are Dart `double`. The three pages still carry the old wording; the revisit note in the plan covers the risk, and the wording can be updated with it. |
| Derived entities | The three results have no row `revision` and are written only by the calculator. | They implement `SyncScoped` with the `derived` scope, so the replicated-change applier can tell them apart. The `entityType` getter is not needed, since the unit of work never saves them. |
| Provenance stamps | Each result carries a configuration revision, a matrix revision and a calculation version, and is stale when any differs from the current one. | A shared `isStaleResult` check backs an `isStale` method on each class. The calculator decides what is current. |
| Derived rules not checked | One selected flight per round, one standing per pilot per round, and ranking order span rows and need the calculator. | Left to the calculator and repositories. The classes check only single-row rules such as positive places and non-negative points. |
| Backend-only revisions | `ParticipantAccountLink` and `PublicationIdentity` have a row `revision`; the other seven backend-only entities do not. Backend-only entities never synchronize. | `BackendOnly` is a marker with no members, so the two keep a `revision` field (default 0) without implementing `Synchronizable`. |
| Account rules | The `Account` page restricts email, verification and admin by `kind`. | Enforced per instance: email is stored lowercase, a guest is never verified, local and deleted accounts have no email, the deleted-user account is never archived, only a registered account is a system admin, and `archived_at` is set exactly when archived. Uniqueness across accounts is left to the backend. |
| Publication rules | The pages say an unclaimed publication is found by its verification email and that redaction deletes details. | A claimed publication has an owner profile and an unclaimed one a verification email. A redacted `PublicationParticipant` holds neither details nor a public profile. A `DelistRequest` decision records who, when and why together. |
| Privacy marker and test | The plan lists `ParticipantProfile`, `AccountIdentity`, `Invitation` and the director-only parts of `AuditEvent` as private. `AuditEvent` is one row type, not split. | `PrivateData` marks all four, with the whole of `AuditEvent` marked. A test keeps hand-written field lists for `PublicationProjection` and `PublicationParticipant` and fails when a field is added or a private field name appears. |
| Scope table and export audit | The plan calls for a single test of all 48 expected scopes. | `scope_table_test.dart` decodes the first example row of every entity through the public barrel, checks its scope against the README table (computed scopes allow each possible value), and checks that synchronizable types name themselves. `LandingResult` is the one entity with no scope. |
| Library boundaries | The plan asks for a check that `lib/` imports only a short list of libraries. | `library_boundaries_test.dart` allows `dart:core`, `dart:convert`, `dart:math`, `equatable`, `json_annotation`, `logging` and the package itself, and rejects `dart:io`, `dart:html`, `dart:ffi` and `dart:isolate`. `dart:math` is used by `Id`. |
| Ticket close-out | All 48 entities are modeled. Nothing is skipped by the example harness. | Status set to In-Review, work items and acceptance criteria ticked, and `plan/INDEX.md` gets a Data Model section. Ticket 036 can start. |
