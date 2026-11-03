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
- `owner_account_id` is the signed-in account, otherwise this installation's Local account. It syncs through the contest stream like any other contest, once the director is signed in.
- Time zone: GliderScore dates are naive. The contest uses the importing installation's time zone; the end date equals the start date.

### Atomicity and repeats

- One database transaction per competition. A failed competition leaves nothing of itself and does not undo the others; the result lists each.
- A competition that was already imported (a provenance row for the same source system, competition number and file fingerprint) is refused with "already imported on date". Re-importing a changed file is #576 (milestone M4).

### Provenance: one `import_provenance` table

Stamps are rows in one source-neutral table, not columns on each entity, so later phases and #576 add rows and not schema.

| Column                | Notes                                                                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                  | UUIDv7                                                                                                                                             |
| `contest_id`          | Set for contest and participation rows; null for profile rows (profiles belong to the director, not a contest)                                     |
| `entity_type`         | `Contest`, `ContestParticipation` or `ParticipantProfile` (later phases add their own)                                                             |
| `entity_id`           | The stamped entity                                                                                                                                 |
| `source_system`       | `gliderscore`                                                                                                                                      |
| `source_keys`         | JSON object of source keys: competition number for a contest, competition number plus pilot number for a participation, pilot number for a profile |
| `file_fingerprint`    | Hash of the source file (and its file name), the same for every row of one import                                                                  |
| `import_operation_id` | One id per wizard run, shared by every row it wrote                                                                                                |
| `tool_version`        | The importer version that wrote the row                                                                                                            |
| `imported_at`         | UTC time                                                                                                                                           |

Rules:

- Rows for the contest, every participation, and every profile the import creates or updates (once per operation, even when several competitions share a pilot).
- Phase A profiles stay unstamped. A later import stamps them when it matches them by the phase A matching rules.
- A stamp is never shown as editable data, never takes part in matching (phase A rules are unchanged), and never changes how an entity behaves.
- Rows with a `contest_id` travel with `.rcsoar` export and sync through the contest stream like the entity they describe. Profile rows follow the director's participants list. The table is classified in `exchangeClassByTable` (contest rows exported, profile rows exported only for profiles the contest references).
- Deleting an entity deletes its stamp.
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
