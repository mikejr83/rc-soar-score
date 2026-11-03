# ADR 0006: Persistence of imported GliderScore contests

- Status: proposed
- Date: 2026-11-03
- Decision issue: #743 (phase B of the GliderScore import, epic #742; replaces #566 for phase B)

## Context

Phase A (PR #707) imports GliderScore pilots into the director's participants list. Phase B turns a GliderScore competition into a Soar Score contest with its configuration and participants, but with no draw, flights or scores. Phases C (draw) and D (scores) follow under #564. The mapping rules are in `plan/research/gliderscore-mdb-import/mapping-plan.md` (sections 5.1, 5.2 and 5.4). Decisions by Mike (2026-11-03): later phases fill the same contest, and participations and profiles carry the same provenance as the contest.

## Decision

### Lifecycle (mapping plan D8)

- A phase B contest is created in `Configuring`. It has no matrix, so no later state is reachable (`contest-state-and-transitions.md`). It is never `Completed`, whatever the source competition looked like.
- `scoring_access` is `Closed` and `admin_lock` is `Unlocked`. No results hiding, no publication.
- The contest shows a note that the draw and scores were not imported. The note is derived from the provenance row (a contest with an import stamp and an empty draw), not stored as text, so it disappears when a later phase fills the contest.
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
- If the target has no Local account id (a damaged installation), persistence stops **before anything is written** with the reason code `import_no_account` and the wizard shows an error. This is the mapping plan's rule (5.3): never mint an invalid owner reference. Profiles the import creates get the same owner. When a Local account is later claimed, ownership is re-pointed with the rest of the director's rows; provenance rows reference entity ids, not accounts, so they keep working.
- The contest syncs through the contest stream like any other contest, once the director is signed in.
- Time zone: GliderScore dates are naive. The contest uses the importing installation's time zone; the end date equals the start date.

### Atomicity and repeats

- One database transaction per competition. A failed competition leaves nothing of itself (contest, participations, provenance, audit events) and does not undo the others; the result lists each.
- **Uniqueness is per competition and owner**, not per source file. A second competition of the same file is a different row; the same competition from a changed file (different fingerprint) is a re-import and belongs to #576, not refused as a duplicate here.
- The invariant is a **unique index**, not a pre-check. Contest provenance rows carry `dedupe_key = <owner_account_id>:gliderscore:<file_fingerprint>:<comp_no>` (null on all other rows) with a unique index: partial (`WHERE dedupe_key IS NOT NULL`) on PostgreSQL, plain unique on SQLite, where nulls are distinct. A pre-check gives the friendly "already imported on date" message, but two simultaneous imports can both pass it, so the importer inserts the contest and its provenance row first inside the transaction and treats a unique violation (SQLite constraint unique, PostgreSQL `23505`) as the same outcome: roll back that competition and report `already_imported` with the earlier import's date and operation id. The other competitions proceed.
- Two directors importing the same file on a shared server do not collide, because the owner is part of the key. When a Local account is claimed, the key is rewritten with the claimed account id together with the other rows.
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
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                  | UUIDv7                                                                                                                                                                                         |
| `contest_id`          | Set for contest and participation rows; null for profile rows (profiles belong to the director, not a contest)                                                                                 |
| `entity_type`         | `Contest`, `ContestParticipation` or `ParticipantProfile` (later phases add their own)                                                                                                         |
| `entity_id`           | The stamped entity                                                                                                                                                                             |
| `source_system`       | `gliderscore`                                                                                                                                                                                  |
| `source_keys`         | JSON object of source keys: competition number for a contest, competition number plus pilot number for a participation, pilot number for a profile                                             |
| `file_fingerprint`    | Hash of the source file (and its file name), the same for every row of one import                                                                                                              |
| `source_values`       | Contest rows only: JSON object of source values that have no Soar Score field and are kept for review and later phases, for example `{"lane_count": 6, "landing_table_no": 9}`; null elsewhere |
| `dedupe_key`          | Contest rows only: `<owner_account_id>:gliderscore:<file_fingerprint>:<comp_no>`; unique index (see above)                                                                                     |
| `import_operation_id` | One id per wizard run, shared by every row it wrote                                                                                                                                            |
| `tool_version`        | The importer version that wrote the row                                                                                                                                                        |
| `imported_at`         | UTC time                                                                                                                                                                                       |

Rules:

- Rows for the contest, every participation, and every profile the import creates or updates (once per operation, even when several competitions share a pilot).
- Phase A profiles stay unstamped. A later import stamps them when it matches them by the phase A matching rules.
- A stamp is never shown as editable data, never takes part in matching (phase A rules are unchanged), and never changes how an entity behaves.
- Rows with a `contest_id` travel with `.rcsoar` export and sync through the contest stream like the entity they describe. Profile rows follow the director's participants list. The table is classified in `exchangeClassByTable` (contest rows exported, profile rows exported only for profiles the contest references).
- **`source_values`:** never editable, never read by scoring or draw, exported and synced with the row. `lane_count` is `durNbrOfLanes` when it is above 0 (Soar Score has `lane_mode` only; the valid lanes of a drawn group are `1..capacity`, so the count is kept, not configured). The draw phase compares it with the drawn capacity and warns when they differ. `landing_table_no` is GliderScore's `durLndg` when it is not the default.
- **Canonical `source_keys`:** a JSON object with keys sorted, integers as plain decimals (no leading zeros, no floats), no whitespace. One helper builds it and the `dedupe_key`, and is unit-tested; comparisons never use a differently serialised copy.
- Deleting an entity deletes its stamp. A profile stamped by several imports holds one row per import operation, not one per competition. Deleting one imported contest removes its contest and participation stamps only; profile stamps belong to the director's participants list and stay.
- Stamps are not personal data beyond what the entity already holds: source keys are GliderScore row numbers, not names.

### Schema

Schema changes go in version 1 in place (a director deletes a stale local `soar_score.db`). `database.g.dart` is regenerated. Tests run on SQLite and PostgreSQL.

## Rejected options

- **Provenance columns on every entity:** a schema change per entity and per later phase.
- **Provenance in the contest only:** profiles and participations would carry no source, and a later phase could not tell which participation came from which GliderScore row.
- **Merging a re-import into a contest that already has a draw or scores:** needs the compare-and-reconcile design of #576 and is not needed for the first release.
- **A second contest per phase:** testers would reconcile two contests by hand.

## Consequences

- Data-model docs: the persistence ticket (#746) adds `plan/data-model/entities/import_provenance.md` with its example JSON and Dart model (the entity catalog test requires all three together), and a line in `contest.md` saying a contest may carry an import stamp.
- The persistence ticket (#746) implements the table and the one-transaction-per-competition importer; the wizard (#747) shows the "draw and scores not imported" note and the already-imported refusal.
- Phases C and D build on the same table and must check the empty-draw rule before filling.
- B3 tests (#746) must cover: the unique index on both databases; two concurrent imports of one competition leave exactly one contest and report `already_imported` for the other; a different fingerprint is allowed; delete then re-import works; signed-in, local-only and missing-account (`import_no_account`, nothing written) targets; audit events present after success and absent after a rolled-back competition; one profile shared by two competitions gets one stamp per operation and survives deleting one contest.
