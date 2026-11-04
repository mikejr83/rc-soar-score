# ADR 0006: Persistence of imported GliderScore contests

- Status: proposed
- Date: 2026-11-03
- Decision issue: #743 (phase B of the GliderScore import, epic #742; replaces #566 for phase B)
- Amended 2026-11-04 by #767 (phase C, epic #766): see "Amendment: restore semantics and the draw import". Where the amendment and the text above differ, the amendment wins.

## Context

Phase A (PR #707) imports GliderScore pilots into the director's participants list. Phase B turns a GliderScore competition into a Soar Score contest with its configuration and participants, but with no draw, flights or scores. Phases C (draw) and D (scores) follow under #564. The mapping rules are in `plan/research/gliderscore-mdb-import/mapping-plan.md` (sections 5.1, 5.2 and 5.4). Decisions by Mike (2026-11-03): later phases fill the same contest, and participations and profiles carry the same provenance as the contest.

## Decision

### Lifecycle (mapping plan D8)

- A phase B contest is created in `Configuring`. It has no matrix, so no later state is reachable (`contest-state-and-transitions.md`). It is never `Completed`, whatever the source competition looked like.
- `scoring_access` is `Closed` and `admin_lock` is `Unlocked`. No results hiding, no publication.
- The contest shows a note that the draw and scores were not imported (refined by the amendment below). The note is derived from the provenance row (a contest with an import stamp and an empty draw), not stored as text, so it disappears when a later phase fills the contest.
- Retired pilots stay active (a retirement is a round-bound fact and there are no rounds yet); the import warns.

### Later phases fill the same contest

- Phases C and D find the contest through its provenance row (source system, competition number, file fingerprint) and add the draw and scores to it. They do not create a second contest.
- A contest is filled only while its draw and scores are empty. Otherwise the phase refuses, with a reason. Merging into a contest that already has a draw or scores is not designed; real use decides whether it is needed.
- A phase B contest is therefore the starting point of the same contest, not a throwaway.

### Profile pin (mapping plan D10)

- The contest's first configuration revision pins the newest published system F5J discipline profile version, with the GliderScore values stored as the resolved settings on that revision (mapping plan 5.2). No profile versions are created.
- When no compatible published version exists, the competition is blocked with a reason code and nothing is written for it.

### Ownership and sync (mapping plan D11)

- An imported contest is an editable contest, the same as one the director created by hand (like the `.rcsoar` import of #214).
- `owner_account_id` is the signed-in account, otherwise this installation's Local account. The importer takes an `ImportTarget` (the `ContestImporter` type of #214): `localAccountId` is required, `signedInAccountId` is optional, and the acting account is `signedInAccountId ?? localAccountId`. Every installation creates its Local account at first start, so an unsigned import always has an owner.
- If the target has no Local account id (a damaged installation), persistence stops **before anything is written** with the reason code `import_no_account` and the wizard shows an error. This is the mapping plan's rule (5.3): never mint an invalid owner reference. Profiles the import creates get the same owner. When a Local account is later claimed, ownership is re-pointed with the rest of the director's rows; the provenance rows carry `owner_account_id` too and are re-pointed with them. Their `dedupe_key` has no owner in it, so the re-point needs no special case.
- The contest syncs through the contest stream like any other contest, once the director is signed in. The `ImportProvenance` table is **director-scoped as a whole** (Mike, 2026-11-03: it belongs to the contest director's account), revisioned, synced through the director stream with the participants list. A contest stamp therefore does not travel in the contest stream; a `.rcsoar` file still carries the contest's and participations' stamps (below).
- Time zone: GliderScore dates are naive. The contest uses the importing installation's time zone; the end date equals the start date.

### Atomicity and repeats

- One database transaction per competition. A failed competition leaves nothing of itself (contest, participations, provenance, audit events) and does not undo the others; the result lists each.
- **Uniqueness is per competition and owner**, not per source file. A second competition of the same file is a different row; the same competition from a changed file (different fingerprint) is a re-import and belongs to #576, not refused as a duplicate here.
- The invariant is a **unique index** on `(owner_account_id, dedupe_key)`, not a pre-check. Contest provenance rows carry `dedupe_key = <source_system>:<file_fingerprint>:<comp_no>` (null on all other rows). The index is plain unique on both databases: SQLite and PostgreSQL both treat nulls as distinct, so rows without a key never clash and no `WHERE` clause is needed. A pre-check gives the friendly "already imported on date" message, but two simultaneous imports can both pass it, so the importer inserts the contest and its provenance row first inside the transaction and treats a unique violation (SQLite constraint unique, PostgreSQL `23505`) as the same outcome: roll back that competition and report `already_imported` with the earlier import's date and operation id. The other competitions proceed.
- Two more unique indexes keep the stamps unambiguous: one stamp per contest or participation (`stamped_entity_type`, `stamped_entity_id`, excluding profiles) and one stamp per profile and import operation (`stamped_entity_id`, `import_operation_id`). The model also enforces the closed entity-type and source sets, the source keys per type, and that a dedupe key matches its row.
- Two directors importing the same file on a shared server do not collide, because the owner is part of the index. The owner is **not** part of the key text, so claiming a Local account re-points `owner_account_id` like any other row and the key stays valid.
- Deleting a contest deletes its provenance rows, including the key, so a deleted contest can be imported again.
- Re-importing a changed file is #576 (milestone M4).

### Audit events

Written in the same transaction as the competition, so they roll back with it:

- One `Contest` event, action `StateTransition`, for the import-specific Created to Configuring transition the mapping plan asks for (section on lifecycle in the persistence compatibility notes). No new `AuditAction` value is added, so there is no migration. Scope is the contest; `reason` is `import:gliderscore:<import_operation_id>`.
- One `ParticipantProfile` event for each profile the import creates or updates, action `StateTransition` with the same reason (the enum has no create or update action, and the retirement audit of #660 reuses `StateTransition` the same way), scoped by `owner_account_id`.
- No per-participation events: participations are part of the contest's creation, not a contested change.
- Actor is the acting account (`signedInAccountId ?? localAccountId`), authority is the director's own, `installation_id` is set. The operation id in `reason` joins audit to provenance.
- If an audit insert fails, the competition fails. The `Completed` import of a fully scored competition is a phase D decision; phase B never produces it.

### Provenance: one `import_provenance` table

Stamps are rows in one source-neutral table, not columns on each entity, so later phases and #576 add rows and not schema.

| Column                | Notes                                                                                                                                                                                          |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| `id`                  | UUIDv7                                                                                                                                                                                         |
| `contest_id`          | Set for contest and participation rows; null for profile rows (profiles belong to the director, not a contest)                                                                                 |
| `owner_account_id`    | The director the stamps belong to; the sync scope key                                                                                                                                          |
| `stamped_entity_type` | `Contest`, `ContestParticipation` or `ParticipantProfile` (later phases add their own)                                                                                                         |
| `stamped_entity_id`   | The stamped entity (named so it cannot be mistaken for `Synchronizable.entityType`)                                                                                                            |     |
| `source_system`       | `gliderscore`                                                                                                                                                                                  |
| `source_keys`         | JSON object of source keys: competition number for a contest, competition number plus pilot number for a participation, pilot number for a profile                                             |
| `file_fingerprint`    | Hash of the source file (and its file name), the same for every row of one import                                                                                                              |
| `source_values`       | Contest rows only: JSON object of source values that have no Soar Score field and are kept for review and later phases, for example `{"lane_count": 6, "landing_table_no": 9}`; null elsewhere |
| `dedupe_key`          | Contest rows only: `gliderscore:<file_fingerprint>:<comp_no>`; unique with the owner (see above)                                                                                               |
| `import_operation_id` | One id per wizard run, shared by every row it wrote                                                                                                                                            |
| `tool_version`        | The importer version that wrote the row                                                                                                                                                        |
| `imported_at`         | UTC time                                                                                                                                                                                       |

Rules:

- Rows for the contest, every participation, and every profile the import creates or updates (once per operation, even when several competitions share a pilot).
- Phase A profiles stay unstamped. A later import stamps them when it matches them by the phase A matching rules.
- A stamp is never shown as editable data, never takes part in matching (phase A rules are unchanged), and never changes how an entity behaves.
- Rows with a `contest_id` travel with the `.rcsoar` export (the table is a contest-class exchange table, found by `contest_id`) and are re-pointed to the importing account. Profile rows (no `contest_id`) are director data: they sync with the participants list and are **not** part of a contest file.
- **`source_values`:** never editable, never read by scoring or draw, exported and synced with the row. `lane_count` is `durNbrOfLanes` when it is above 0 (Soar Score has `lane_mode` only; the valid lanes of a drawn group are `1..capacity`, so the count is kept, not configured). The draw phase compares it with the drawn capacity and warns when they differ. `landing_table_no` is GliderScore's `durLndg` when it is not the default.
- **Canonical `source_keys`:** a JSON object with keys sorted, integers as plain decimals (no leading zeros, no floats), no whitespace. One helper builds it and the `dedupe_key`, and is unit-tested; comparisons never use a differently serialised copy.
- Deleting an entity deletes its stamp. A profile stamped by several imports holds one row per import operation, not one per competition. Deleting one imported contest removes its contest and participation stamps only; profile stamps belong to the director's participants list and stay.
- Stamps are not personal data beyond what the entity already holds: source keys are GliderScore row numbers, not names.

### Schema

Schema changes go in version 1 in place (a director deletes a stale local `soar_score.db`). `database.g.dart` is regenerated. Tests run on SQLite and PostgreSQL.

## Amendment: restore semantics and the draw import (2026-11-04, #767)

Decided by Mike on 2026-11-04 while planning phase C. It amends the lifecycle, fill, audit and note rules above for phases C and D. Phase B's code is unchanged.

### The import is a point-in-time restore

- The import restores a completed contest, or the last state of one in competition. It is not a replay of how the contest would have been created and scored in Soar Score. Nothing is fabricated: no score attempts, no review history, no entry times.
- Phases B and C are **build stages** of the restore. `Configuring` (after B) and `Ready` (after C) are not states a director is meant to leave a contest in after a restore. Phase D brings the contest to the snapshot's final state.
- Final state (phase D): `Completed` or `Running`, chosen per competition by the director with a "Completed" checkbox. It is preselected, and unchecked where a flown round has unscored flights. Checking it anyway counts those flights as not entered. Trailing rounds with no scored flight restore as `Cancelled` when the contest is `Completed`. A completed restore comes in with its rounds and groups locked.
- **Audit:** phases C and D write their events with the existing `Restoration` action (`AuditAction.restoration`) and `reason` `import:gliderscore:<import_operation_id>`. This replaces the `StateTransition` action this ADR names for the Created to Configuring event. The events phase B already writes stay as written (no migration).

### Fill rule

- **Phase C** fills a phase B contest that has **no matrix and no accepted scores**. Otherwise the competition is skipped with a reason code. It ends with the contest `Ready`.
- **Phase D** works on a phase B contest with **no accepted scores** and **replaces a phase C draw** in one transaction: draw and scores are written together. This replaces "D needs a contest whose draw was imported by C". Scores entered by hand make phase D refuse.
- The file must still match the stamp (same fingerprint); otherwise the phase refuses until the re-import of #576.
- The phase C draw is therefore a build stage that phase D can overwrite. No migration is provided: the only tester starts from a fresh database, and to import again a director deletes the contest.

### Draw rules (phase C)

- The draw comes from `Scores`, one row per drawn flight whether scored or not. Pilots are found through the phase B participation stamps, never by name.
- **Lanes:** GliderScore has only two lane settings. A lane count above 0 means `Random` lane mode and lane = rank of `SeqNo` within the group (the first listed pilot is lane 1; gaps close up; a pilot beyond the lane count gets the next lane, with a warning). A lane count of 0 means no lanes: the lane stays empty and the `SeqNo` positions are kept in the stamp.
- Observed groups win over the configured groups per round, with a warning. Group sizes are imported as drawn, with a warning when they differ from the derived sizes.
- Every drawn row of every pilot is imported, retired or not. **Phase D** sets `retired_at_round` inside the restore (a retirement is an overlay; the assignments stay as history).
- Matrix revision: `random_seed` 0, `algorithm_version` `import:gliderscore/1`, `draw_mode` `StandardManOnMan`, empty `seeding_snapshot`; a warning says the draw is history, not reproducible.

### Draw stamps

- The **matrix revision** is stamped: one `MatrixRevision` row in `import_provenance` per revision, with `source_keys` `comp_no` and `task_no`, and `source_values` holding the round range and group count. A competition with several revisions (runs of rounds with different group counts) has one row for each.
- For competitions with lane count 0, `source_values` also holds the `SeqNo` position of every assignment (keyed by round, group and pilot number), because the lane field is empty.
- There are **no per-assignment stamps**. Phase D matches scores to assignments by competition, task, round, group and pilot number, which the draw carries.
- `stamped_entity_type` gains `MatrixRevision`. The stamp has the same operation id and fingerprint as the contest's. It travels with the contest in a `.rcsoar` file and is deleted with the contest.

### Contest note

The note that says what was not imported is derived from the stamps, never stored: a contest with an import stamp and no matrix revision stamp shows "draw and scores were not imported"; one with a matrix stamp and no score stamp shows "scores were not imported"; it disappears when phase D has filled the contest.

## Rejected options

- **Provenance columns on every entity:** a schema change per entity and per later phase.
- **Provenance in the contest only:** profiles and participations would carry no source, and a later phase could not tell which participation came from which GliderScore row.
- **Merging a re-import into a contest that already has a draw or scores:** needs the compare-and-reconcile design of #576 and is not needed for the first release.
- **A second contest per phase:** testers would reconcile two contests by hand.

## Implementation

`ContestImportRepository` (contract in `soar_score_core`, Drift implementation in `soar_score_data`) has two calls. `stampProfiles` stamps the profiles an operation created or updated, once per operation, before any competition is written. `importCompetition` writes one competition in one unit of work and returns `CompetitionImported`, `CompetitionAlreadyImported` or `CompetitionImportFailed` with a stable code; it never throws for a competition-level problem. Each write in the unit of work gets its own request id (`<id>:<n>`), because the mutation log is unique on scope and request id.

## Consequences

- Data-model docs: the persistence ticket (#746) adds `plan/data-model/entities/import_provenance.md` with its example JSON and Dart model (the entity catalog test requires all three together), and a line in `contest.md` saying a contest may carry an import stamp.
- The persistence ticket (#746) implements the table and the one-transaction-per-competition importer; the wizard (#747) shows the "draw and scores not imported" note and the already-imported refusal.
- Phases C and D build on the same table and must check the empty-draw rule before filling.
- B3 tests (#746) must cover: the unique index on both databases; two concurrent imports of one competition leave exactly one contest and report `already_imported` for the other; a different fingerprint is allowed; delete then re-import works; signed-in, local-only and missing-account (`import_no_account`, nothing written) targets; audit events present after success and absent after a rolled-back competition; one profile shared by two competitions gets one stamp per operation and survives deleting one contest.
