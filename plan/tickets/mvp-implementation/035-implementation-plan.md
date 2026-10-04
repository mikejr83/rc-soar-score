# Ticket 035 — Implementation Plan for the Canonical Domain Models

Companion to [035-create-data-models.md](035-create-data-models.md). The ticket says what must exist; this plan says how and in what order to build it in `packages/soar_score_core`, how to keep the 48 models consistent, and what to confirm before writing code. Status: **draft for review**.

## 1. Starting point

- `packages/soar_score_core` has `Id` (UUIDv7), a placeholder `Contest(id, name, startedAt)`, `Repository` and `ContestRepository`, and one enum. Its only runtime dependency is `logging`. There is no `json_annotation` yet.
- `Contest` is used outside core in `packages/soar_score_data` (`lib/repositories/contest_repository.dart` and its SQLite test). The real `Contest` has different fields (`start_date_time`, `end_date_time`, `timezone`, three state enums, `revision`, and so on), so expanding it breaks that code. The data package needs a minimal compile fix in the same PR; the real mapping is ticket 036.
- The spec is 48 entity documents (`plan/data-model/entities/`), the generated [enumerations.md](../../data-model/enumerations.md) (52 enum fields across 31 entities), and worked JSON in `plan/data-model/examples/entities/`.
- The pre-implementation decisions that define fields (010, 012–016) are all `ready`, so no field needs to be marked provisional.

## 2. Findings to resolve first

These are mismatches between the ticket and the repository. Record the outcome in the discrepancy section the ticket already asks for.

| #   | Finding                                                                                                                                                                                                                     | Proposed resolution                                                                                       |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 1   | The ticket says "load every JSON file in `examples/entities/`". The examples are 8 Markdown files holding about 50 fenced `json` blocks, each under a `## EntityName` heading. Some entities have several rows.             | The round-trip test parses the fenced blocks and maps each heading to a model. Update the ticket wording. |
| 2   | `reconciliation-findings.md` says "47 entities"; the ERD, the catalog and `entities/` all have 48.                                                                                                                          | Fix the reconciliation summary to 48.                                                                     |
| 3   | `Role`, `LandingTable` and `LandingResult` are director data when `owner_account_id` is set and system data when it is null. A pure per-type sync-scope marker cannot express that.                                         | Scope is per instance for these three (see §3.3). The type-level marker covers the other 45.              |
| 4   | Enum text is not uniformly cased (`registered`, `active` vs `Pilot`, `Success`, `MagicURL`). Casing must match the check constraints in 036 and the JSON on the wire.                                                       | Every enum value is declared with an explicit `@JsonValue`; never derive it from the Dart identifier.     |
| 5   | The placeholder `Contest.startedAt` has no counterpart in the entity (`start_date_time` and `end_date_time` are both required).                                                                                             | Rename and extend, and update the data package in the same PR.                                            |
| 6   | The spec uses `Decimal` for scores. Dart has no decimal in the standard library, `AGENTS.md` bans new runtime dependencies without updating it, and the ticket forbids floating point for scores.                           | Decision D2 below.                                                                                        |
| 7   | Where an entity page, its example, and `enumerations.md` disagree, the order of authority is: architecture requirements, then the entity page, then the example. `enumerations.md` is generated, so it is never the source. | Report any disagreement and fix the lower-authority document in the same PR.                              |

## 3. Design

### 3.1 Layout

One class per file, grouped by family. Enums stay in `lib/enums/` with a barrel. Generated `*.g.dart` files are checked in.

```text
lib/
  models/
    shared/        revision.dart, scoring_uuid.dart, utc_timestamp.dart, versioned_payload.dart, sync_scope.dart, score_value.dart
    sync/          mutation_record.dart, conflict_record.dart, tombstone.dart, audit_event.dart, installation.dart, ...
    contest/       contest.dart, contest_configuration_revision.dart, contest_configuration_preset.dart
    discipline/    discipline_profile.dart, discipline_config_field.dart, ...
    landing/       landing_table.dart, landing_result.dart
    participants/  participant_profile.dart, contest_participation.dart, role.dart, ...
    teams/         team.dart, team_membership.dart, model_catalog.dart, contest_model_link.dart
    matrix/        matrix_revision.dart, round.dart, round_group.dart, matrix_assignment.dart, re_flight.dart, ...
    scores/        score_placeholder.dart, score_attempt.dart, official_score.dart, review_request.dart, invitation.dart
    results/       flight_result.dart, participation_standing.dart, team_standing.dart
    accounts/      account.dart, account_identity.dart, account_public_profile.dart
    publication/   publication_identity.dart, publication_projection.dart, publication_participant.dart, delist_request.dart
  enums/           one file per enum, plus enums.dart
  repositories/    existing contracts, plus unit_of_work.dart, replicated_change_applier.dart, sync_store.dart
test/              mirrors lib/, one test file per family (split further when a file passes about 300 lines)
test/examples/     round-trip test over the fenced JSON in plan/data-model/examples/entities/
```

`Id` and `ContestRepository` stay where they are. Models under `lib/models/` that are not in a family folder today move into one as they are touched.

### 3.2 Model conventions

- Immutable classes with `final` fields and a `const` or validating constructor. Validation (blank names, ranges, date ordering) throws `ArgumentError`, as `Contest` does today.
- `@JsonSerializable(fieldRename: FieldRename.snake)` so Dart `camelCase` fields serialize as the `snake_case` keys in the entity documents. Required and nullable fields follow the Required column exactly. The example JSON writes absent optionals as explicit `null`, so use `includeIfNull: true`.
- Cross-entity references are `Id` fields, never object references. Custom `JsonConverter`s: `Id` ⇄ string, `DateTime` ⇄ UTC ISO 8601 (rejecting non-UTC offsets on read), `ScoringUuid` ⇄ string.
- `==`, `hashCode` and `toString` hand-written, matching the existing `Contest`. This is verbose for 48 classes; see D1.
- Update semantics: `copyWith` only where a use case needs it, not blanket. Revisions are not bumped by models; the unit of work bumps them (§3.5).

### 3.3 Sync scope marker

A `SyncScope` enum (`contest`, `director`, `system`, `issued`, `derived`, `backendOnly`) and one interface:

```dart
abstract interface class Synchronizable {
  SyncScope get syncScope;
  int get revision;
}
```

- Contest, director, system, issued and derived models implement it with a constant scope. Backend-only models implement a smaller `BackendOnly` marker and have no `revision` requirement unless their document has one.
- `Role`, `LandingTable` and `LandingResult` compute `syncScope` from `ownerAccountId` (`null` is `system`, otherwise `director`). Tests cover both.
- A single test lists the expected scope of all 48 entities from the README table, so the code and the table cannot drift apart.

### 3.4 Privacy by construction

- `ProtectedCredential` wraps the invitation credential hash. Its `toString` is redacted and it is excluded from `Invitation.toJson` for any public or log use; the sync/API JSON path carries it only through an explicit method.
- A `PrivateData` marker interface on `ParticipantProfile`, `AccountIdentity`, `Invitation`, and the director-only parts of `AuditEvent`.
- The publication models (`PublicationProjection`, `PublicationParticipant`) must not hold any `PrivateData` field. A reflection-free test enforces this with a hand-kept list, so adding a private field to a public model fails a test.

### 3.5 Repository contracts (contracts only)

Sketch, to be refined against ticket 037 before coding:

- `UnitOfWork`: `Future<T> run<T>(Future<T> Function(WriteContext) body)`. `WriteContext` offers `save(entity, {required MutationMetadata})` and `delete(entity)`. The implementation (036) stores the entity, bumps `revision`, and writes the `MutationRecord` (or `Tombstone`) in one transaction. Core never bumps a revision itself.
- `ReplicatedChangeApplier`: `apply(ReplicatedChange)`, keeping the server revision and sequence, creating no pending mutation, and throwing for derived entities.
- `SyncStore`: outbox read (`pendingMutations(scope)`), outcome update, cursor read and write, replicated-change apply, and queries for conflicts and sync status. Typed against a sealed `SyncScopeKey` (a contest id or a director's account id).
- Per-entity repositories (extending `Repository<T>`) only where something reads by a non-primary key. Defer the rest to the first consumer.

### 3.6 Versioned payloads

`MutationRecord` carries `entityType` (an enum of the synchronizable entity names, used to pick the decoder), `schemaVersion` and a `payload` map. `VersionedPayload` holds `{version, data}` and a registry maps `(entityType, version)` to a decoder, so an older installation's mutation can still be decoded.

## 4. Decisions for the owner

| #   | Decision                                           | Recommendation                                                                                                                                                                                                                                                                                               |
| --- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| D1  | Equality and `copyWith` boilerplate for 48 classes | Add `equatable` as a runtime dependency (tiny, pure Dart) and update `packages/soar_score_core/AGENTS.md`. The alternative, hand-written equality everywhere, adds roughly 15 lines per class and many chances for mistakes. `freezed` is heavier than needed.                                               |
| D2  | Decimal representation for scores                  | A small `ScoreValue` value type wrapping a scaled `BigInt` or `int` with a fixed scale (suggest 4 decimal places, to be confirmed against the discipline formulas), serialized as a JSON number. No new dependency, no floating point in storage or comparison. Ticket 036 stores it as scaled integer text. |
| D3  | Whether `Contest` keeps `startedAt` as an alias    | No. Remove it. The only consumer is the data package, which is updated in the same PR.                                                                                                                                                                                                                       |

I recommend accepting all three. D1 and D2 change `AGENTS.md` / `pubspec.yaml`, so they need your go-ahead before PR 1.

## 5. Delivery sequence

One PR per row, each leaving `dart analyze` and `dart test` green in core, the data package compiling, and `npx prettier --check "**/*.md"` clean. Because models refer to each other only by `Id`, families have no compile-time dependencies on one another; the order below is about what later work needs.

| PR  | Content                                                                                                                                                                                              | Why here                                                                             |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 1   | Dependencies (`json_annotation`, `json_serializable`, `build_runner`, D1), shared building blocks (§3.1 `shared/`, converters, `SyncScope`), enum barrel scaffold, discrepancy section in the ticket | Everything else uses these. Also proves codegen works in the workspace               |
| 2   | Example harness: the Markdown-fence parser and a heading-to-decoder registry. Initially it asserts every entity heading is present and skips unregistered ones with a visible count                  | Each later PR registers its entities and the count of unregistered ones reaches zero |
| 3   | Sync and audit: `MutationRecord`, `ConflictRecord`, `Tombstone`, `AuditEvent`, `Installation`, `InstallationActivation`, `SyncCursor`; `UnitOfWork`, `ReplicatedChangeApplier`, `SyncStore`          | Unblocks 037 and the write path in 036                                               |
| 4   | Contest and configuration: expanded `Contest`, `ContestConfigurationRevision`, `ContestConfigurationPreset`, the contest state enums and `contest-options.md` value types; data package fix-up       | The one existing model; keeps the repository and equality behaviour                  |
| 5   | Disciplines and landing tables (system data)                                                                                                                                                         | Needed by the configuration and scoring families                                     |
| 6   | Participants, roles, teams and models                                                                                                                                                                |                                                                                      |
| 7   | Matrix, assignments and re-flights                                                                                                                                                                   |                                                                                      |
| 8   | Scores and reviews: `ScorePlaceholder`, `ScoreAttempt`, `OfficialScore`, `ReviewRequest`, `Invitation`; independent outcome and lifecycle fields (decision 012); `ProtectedCredential`               | Highest-risk invariants, so it comes after the shared patterns are proven            |
| 9   | Derived results: `FlightResult`, `ParticipationStanding`, `TeamStanding`, with provenance versions                                                                                                   |                                                                                      |
| 10  | Backend-only: accounts, publication; the publication privacy test; final export audit of `soar_score_core.dart`; ticket status and `plan/INDEX.md` updates                                           | Closes the ticket                                                                    |

Each family PR does the same five things: models and enums, generated code, family tests, registration of its entities in the example harness, and a note in the ticket's discrepancy section.

## 6. Test plan

- **Per model:** construction with valid and invalid inputs, equality and hash, and a JSON round trip (`fromJson(toJson(x)) == x`).
- **Examples:** for every fenced block, `toJson(fromJson(block))` equals the original map, key for key. This catches missing fields, renamed keys, dropped nulls and enum casing. The test reads the files under `plan/data-model/examples/entities/` relative to the repository root; test code may do I/O, library code may not.
- **State independence:** tests that vary each state dimension on `Contest` (lifecycle, scoring access, admin lock, hidden-through-round, local archive) without affecting the others, and that publication visibility never produces `PendingDelete`.
- **Score semantics:** missing, explicit zero and retired remain distinct; a second `ScoreAttempt` never mutates the first; an `OfficialScore` revision is a new object.
- **Scope table:** the all-48 expected-scope test (§3.3) and the privacy test (§3.4).
- **Boundaries:** a test or CI check that `lib/` imports nothing outside `dart:core`, `dart:convert`, `logging`, `json_annotation` and `equatable` (if D1 is accepted).
- **Acceptance gate for the ticket:** `dart run build_runner build`, `dart analyze` and `dart test` in `packages/soar_score_core`, then `melos analyze` and `melos test` for the workspace.

## 7. Risks

- **Boilerplate drift.** 48 classes with hand-written conventions will diverge. Mitigation: decide D1 before PR 1 and review PR 3 (the first family) as the template for the rest.
- **Spec drift.** Fields may be added to documents while code is written. Mitigation: the example round-trip test fails on any difference, and each PR re-reads its entity pages.
- **Downstream churn.** Ticket 036 (Drift) and 037 (sync) depend on names chosen here. Mitigation: PR 3 lands the sync contracts early, and 036 starts at the family boundary rather than waiting for PR 10.
- **Repository contract shape.** `UnitOfWork` and `SyncStore` are easy to get subtly wrong. Mitigation: review them against the 037 acceptor and engine sketches before PR 3 merges.

## 8. Not in scope

The scoring and draw engines, the sync protocol and engine, API DTOs (`soar_score_api`), Drift tables and repositories (036), and UI.
