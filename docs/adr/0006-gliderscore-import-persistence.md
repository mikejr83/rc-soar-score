# ADR 0006: Persistence of imported GliderScore contests

- Status: proposed
- Date: 2026-11-03
- Decision issue: #743 (phase B of the GliderScore import, epic #742; replaces #566 for phase B)
- Amended 2026-11-04 by #767 (phase C, epic #766): see "Amendment: restore semantics and the draw import".
- Amended again 2026-11-04 by #767 (phase D, epic #766): see "Amendment 2: the end-to-end restore". Where an amendment and the text above differ, the later amendment wins. Amendment 2 supersedes the fill rule, the fingerprint rules, the dedupe key and the "draw and scores not imported" note of the earlier text.
- Amended by #885: confirmed pilot links are director-scoped active data, separate from historical provenance. Both import flows reuse them; source changes require review and participant deletion clears the links. GliderScore 6 is treated as one logical source per director, so saves and added competitions preserve links. Distinguishing an independent database on a different computer is deferred. The earlier statement that provenance never takes part in matching remains true for historical stamps; the matcher consults active links.

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

| Column | Notes |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| `id` | UUIDv7 |
| `contest_id` | Set for contest and participation rows; null for profile rows (profiles belong to the director, not a contest) |
| `owner_account_id` | The director the stamps belong to; the sync scope key |
| `stamped_entity_type` | `Contest`, `ContestParticipation` or `ParticipantProfile` (later phases add their own) |
| `stamped_entity_id` | The stamped entity (named so it cannot be mistaken for `Synchronizable.entityType`) | |
| `source_system` | `gliderscore` |
| `source_keys` | JSON object of source keys: competition number for a contest, competition number plus pilot number for a participation, pilot number for a profile |
| `file_fingerprint` | Hash of the source file (and its file name), the same for every row of one import |
| `source_values` | Contest rows only: JSON object of source values that have no Soar Score field and are kept for review and later phases, for example `{"lane_count": 6, "landing_table_no": 9}`; null elsewhere |
| `dedupe_key` | Contest rows only: `gliderscore:<file_fingerprint>:<comp_no>`; unique with the owner (see above) |
| `import_operation_id` | One id per wizard run, shared by every row it wrote |
| `tool_version` | The importer version that wrote the row |
| `imported_at` | UTC time |

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

## Amendment 2: the end-to-end restore (2026-11-04, #767, phase D)

Decided by Mike on 2026-11-04. No tester will ever see a phase B or C contest: the feature reaches users as one complete restore, and nothing is added to contests imported by earlier phases (no migration; the only tester starts from a fresh database).

### Superseded

- "Fill only a phase B contest" and "phase D replaces a phase C draw" (fill rule). A restore is one operation that creates or updates everything of a competition.
- "The file must still match the stamp (fingerprint)", and the fingerprint inside the dedupe key. The same competition from a changed file is the same contest.
- "Already imported is refused". A second import updates the contest in place (below).
- The "draw and scores not imported" contest note and the `Configuring` and `Ready` build-stage states. The wizard has a single import flow; the phase B and C steps go away.
- "Re-importing a changed file is #576": the first release covers it as below. What #576 keeps is a diff-and-apply merge, which is not planned.

### One operation per competition

One database transaction per competition creates or updates the contest, its configuration revision, participations, the draw, every scored flight, re-flights, retirements and the final state, then runs the comparison gate. Phase B's contest persistence and phase C's draw persistence become steps inside it. A failed competition leaves nothing of itself and does not undo the others.

### Identity and re-import

- A competition is identified by `CompID` when the row has one (26 of the 38 competitions in the reference file do, from 2019 on). Without one, by competition number + name + date, and the wizard asks for confirmation naming the source file ("update this contest or import as a new one") when the number matches but the name or date differs.
- The identity is stored in the contest stamp's `source_keys` (`comp_id` or `comp_no`, `comp_name`, `comp_date`). The dedupe key is `gliderscore:<identity>` without the file fingerprint; the unique index on `(owner_account_id, dedupe_key)` stays and still decides a race (one winner, the other reports `already_imported`).
- **Re-import replaces the imported contents in place and keeps the contest id.** Participations, draw, scores, re-flights, retirements and state are rewritten from the file in one transaction; removed rows leave tombstones so sync converges. Anything done in Soar Score after the import is lost; there is no diff.
- **Content hash:** the plan carries a hash of the content the file would produce. It is stored in the contest stamp's `source_values`. An equal hash means nothing is written at all (not a revision, not an audit event). The hash covers mapped content only, never the file name or fingerprint, and is the same for the same file every time.
- **Guard:** a re-import into a contest changed in Soar Score since the import (a score entered, a pilot added, the draw changed) shows what will be replaced, with counts, and needs a confirmation. A contest whose results are published is **refused**, with a reason; the director un-publishes first.
- **Participants:** pilots follow the phase A rules (non-blank values overwrite, names never change). A participation no longer in the file is removed if it has no scores, otherwise it is retired. New pilots are added.
- **Locked contests:** a completed, locked contest is unlocked, replaced and locked again according to the checkbox; if the hash is equal it is untouched.

### The restore attempt

An `OfficialScore` must cite the `ScoreAttempt` that produced it. The restore therefore writes **exactly one attempt per scored flight**, marked as an import: authority `Director`, actor the importing account, `source_device` `import:gliderscore`, `client_mutation_id` `gs:<identity>:<task>,<round>,<group>,<reflight>,<pilot>`, `raw_components` holding the GliderScore values verbatim. It is a record of what the file said, not a simulated entry. No review requests, no second attempts, no entry times. The official score has `set_by` the importing account, `set_at` the import instant and `reason` `restored from GliderScore`. Placeholder revisions advance as the normal path advances them (attempt accepted, then official). The earlier sentence "no score attempts" is replaced by: **no review history and no entry times; each restored flight has one restore attempt.**

### Score values

- `Updated = False` rows stay `NotEntered` (a pending flight, not a zero).
- `Time1Mins` is packed `M:SS` and decoded as `(v ~/ 100) * 60 + (v % 100)`; the raw value is kept in `raw_components`.
- `FlightScoreDeduction` is the F5J launch height in metres (Soar computes the height penalty). `Penalty` is `flight_penalty`. `Landing` resolves through the landing table (below).
- `F5JMotorReStarted = 1` with restart option 1 or 2 is a zero with reason `motor_restart`, components kept beside the flag. Option NULL (oldest competitions) keeps the recorded score, keeps the flag as provenance and warns.
- **All-zero flights are imported as entered** (time 0, no landing, height 0, penalty 0) and the calculator produces the zero. A launch height of 0 is not a valid height in Soar Score, so the normalized components of such a flight are empty (no time, no height) and the GliderScore values stay in `raw_components`; the calculator treats a flight with no time or height as a zero. `LandingOver75m` is kept in `raw_components` only and is not turned into an out-of-bounds reason. **No new zero reason** is added; the "imported, reason unknown" idea is dropped. A flight with a time and height whose `RawScore` is 0 is imported as is; the calculator reproduces the zero.
- `Helper`, `Laps`, `DrawFreq`, `ScoresChecked`, `LandingOver75m`, `OriginalRoundNo`, `RawScore` and `NormalisedScore` go to `raw_components` or to the comparison only. `RawScore` and `NormalisedScore` are never stored as results; Soar recomputes.

### Landing table selection

Per competition, the candidates are tried in order: the F5J system default table, the other shipped table, then the table reconstructed from the competition's own `LndgNames` and `LndgPoints`. The first one in which every observed non-zero landing value resolves to exactly one entry that awards the points GliderScore awarded is pinned in the configuration. A semantic match is required, not a name match. If none matches fully, the best candidate is pinned with a per-row warning; the comparison gate then decides whether the competition can be imported.

### Re-flights

Only whole-group re-flights are restored (`ReflyEntireGroup`). The re-flight group is **numbered after the regular groups** of its round; GliderScore's own group number is kept in the stamp. A printed Soar sheet therefore shows a different group number than GliderScore for that re-flight. Roles: a pilot with no score in the original flight is `Awarded`, every other pilot in the group is `GroupMember`. Subset re-flights, moved credits and overlapping task ranges are refused for that competition, with a reason.

### Retirement

A pilot with `Retired = 1` gets `retired_at_round` set to the round after their last scored flight (round 1 if none). It is an overlay: the later assignments stay. The review lists the inferred rounds.

### Lifecycle walk and final state

`ContestLifecycle.complete` works only from `Running`, and the first accepted score moves `Ready` to `Running`. The restore walks the same states inside the transaction (Ready, Running, then Completed if chosen) and writes **one `Restoration` audit event per competition**, not one per step. Final state:

- A competition with no scored flights stays `Ready` and the review says so.
- Otherwise `Running`, or `Completed` when the director's "Completed" checkbox is on. The checkbox is preselected, and unchecked where a flown round has unscored flights; checking it anyway counts those flights as not entered.
- On `Completed`, trailing rounds with no scored flight are restored as `Cancelled`; the contest (`admin_lock`) and its rounds and groups are locked.
- Audit actor, `reason` and `installation_id` follow the earlier rules.

### Comparison gate

Inside the transaction, after everything is written, Soar's calculator is run over the restored flights and compared with GliderScore's `RawScore`. The comparison is **exact**. Any difference rolls the competition back and the wizard says plainly that it could not be imported, naming the first few flights (round, group, pilot number); a log entry holds the rest. It is internal: no report screen, no stored report. `NormalisedScore` (group scores) is measured in tests first and gates only once a tolerance is known. Strictness is revisited once real files have gone through.

### Stamps

- The contest stamp's `source_values` gains the identity, the content hash and the final-state choice.
- A score stamp: one `FlightScore` row per scored flight is **not** written (thousands of rows). A single `Scores` stamp per competition (`stamped_entity_type` `ContestScores`, `source_keys` `comp_no`) records the number of restored flights, the landing table pinned and the hash; it travels with the contest in a `.rcsoar` file and is deleted with it. The restore attempts and official scores are themselves the per-flight provenance (`source_device` `import:gliderscore`).
- `stamped_entity_type` gains `ContestScores`. Re-flight group numbers and retirement inferences are kept in `source_values` of the contest stamp.

### Responsiveness

Reading the file, parsing, mapping and the database writes run off the UI isolate (#774); the wizard shows a progress state and the main thread never waits for a whole competition.

## Rejected options

- **Provenance columns on every entity:** a schema change per entity and per later phase.
- **Provenance in the contest only:** profiles and participations would carry no source, and a later phase could not tell which participation came from which GliderScore row.
- **Merging a re-import into a contest that already has a draw or scores (diff and apply):** needs a rule for every kind of change; replaced in place instead (amendment 2). Revisit when testers ask.
- **An optional attempt reference on `OfficialScore`:** changes a core invariant and every reader (sync, publication, history); one restore attempt per flight instead.
- **A new zero reason for flights with no recorded details:** nothing is silently relabelled; the details are imported as entered and the calculator produces the zero.
- **A second contest per phase:** testers would reconcile two contests by hand.

## Implementation

`ContestImportRepository` (contract in `soar_score_core`, Drift implementation in `soar_score_data`) has two calls. `stampProfiles` stamps the profiles an operation created or updated, once per operation, before any competition is written. `importCompetition` writes one competition in one unit of work and returns `CompetitionImported`, `CompetitionAlreadyImported` or `CompetitionImportFailed` with a stable code; it never throws for a competition-level problem. Each write in the unit of work gets its own request id (`<id>:<n>`), because the mutation log is unique on scope and request id.

## Consequences

- Data-model docs: the persistence ticket (#746) adds `plan/data-model/entities/import_provenance.md` with its example JSON and Dart model (the entity catalog test requires all three together), and a line in `contest.md` saying a contest may carry an import stamp.
- The persistence ticket (#746) implements the table and the one-transaction-per-competition importer; the wizard (#747) shows the "draw and scores not imported" note and the already-imported refusal.
- Phases C and D build on the same table and must check the empty-draw rule before filling.
- B3 tests (#746) must cover: the unique index on both databases; two concurrent imports of one competition leave exactly one contest and report `already_imported` for the other; a different fingerprint is allowed; delete then re-import works; signed-in, local-only and missing-account (`import_no_account`, nothing written) targets; audit events present after success and absent after a rolled-back competition; one profile shared by two competitions gets one stamp per operation and survives deleting one contest.
