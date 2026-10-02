# MatrixRevision

**Relationship to architecture-requirements:** `plan/architecture-requirements/data/matrix-and-assignments.md`, `plan/architecture-requirements/data/matrix-draw.md`  
**Purpose:** Records one draw of the flight matrix: which rounds it covers, the settings and inputs the draw used, the seed and engine version needed to reproduce it, the fairness result, and who created and finalized it. A new draw never overwrites an earlier revision. A revision either extends the matrix with new rounds or replaces unscored rounds from some round to the end of the contest.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Contest  
**Child entities:** Round, MatrixAssignment

## Relationships

- Belongs to a Contest
- May extend an earlier MatrixRevision (`previous_revision_id`), forming a linear chain of finalized draws
- Parent of the Rounds it covers (`first_round` to `last_round`) and of the MatrixAssignments that place pilots in those rounds
- Referenced by ScoreAttempt (`matrix_revision_id`) as the matrix the client held when a score was entered
- Created and finalized by actors (`created_by`, `finalized_by`)

## Fields/Properties

| Field                  | Type        | Required | Default | Description                                                                                                                                                                                                                     |
| ---------------------- | ----------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | UUIDv7      | Yes      | -       | Primary key                                                                                                                                                                                                                     |
| `contest_id`           | UUIDv7      | Yes      | -       | FK Contest                                                                                                                                                                                                                      |
| `revision_number`      | int         | Yes      | -       | Sequential number of this draw within the contest, starting at 1                                                                                                                                                                |
| `previous_revision_id` | UUIDv7      | No       | -       | FK MatrixRevision; the latest finalized revision when this one was created. Null for the first revision                                                                                                                         |
| `first_round`          | int         | Yes      | -       | First round ordinal this revision draws                                                                                                                                                                                         |
| `last_round`           | int         | Yes      | -       | Last round ordinal this revision draws                                                                                                                                                                                          |
| `draw_mode`            | enum        | Yes      | -       | Algorithm used for this revision's rounds: `StandardManOnMan` or `SeededManOnMan`. The preliminary block of a seeded contest is drawn as `StandardManOnMan`, so this can differ from `draw_config.configured_draw_mode`         |
| `random_seed`          | bigint      | Yes      | -       | 32-bit unsigned seed for the PRNG. Generated and stored when the caller supplies none                                                                                                                                           |
| `algorithm_version`    | string      | Yes      | -       | Version tag of the draw engine (e.g. `1.0.0`). Fixes all annealing parameters, so any change to a default requires a new version                                                                                                |
| `draw_config`          | JSON        | Yes      | -       | Settings used for this draw: `schema_version`, `groups_per_round`, `team_protection`, `configured_draw_mode` (the contest's configured mode), and `preliminary_rounds` (seeded mode only)                                       |
| `seeding_snapshot`     | JSON        | Yes      | -       | Snapshot of the draw's inputs: each participating pilot's participation id and team id at draw time, plus seed rank for seeded rounds                                                                                           |
| `fairness_summary`     | JSON        | No       | -       | Fairness report as of this draw, cumulative across all rounds including earlier revisions: max duplicate matchups, matchup histogram, unmet opponent count, lane uniformity index, overall fairness score. Required to finalize |
| `reason`               | string      | No       | -       | Explanation for this revision (e.g. initial draw, rounds added, redraw from round 7)                                                                                                                                            |
| `created_by`           | UUIDv7      | Yes      | -       | FK; actor who created the revision                                                                                                                                                                                              |
| `created_at`           | timestamptz | Yes      | -       | When the revision was created (server time)                                                                                                                                                                                     |
| `finalized_by`         | UUIDv7      | No       | -       | FK; actor who finalized the revision. Write-once                                                                                                                                                                                |
| `finalized_at`         | timestamptz | No       | -       | When the revision was finalized. Write-once; null while a draft                                                                                                                                                                 |

## Invariants and Constraints

- A new draw never overwrites an earlier revision
- (`contest_id`, `revision_number`) is unique
- At most one finalized revision exists per (`contest_id`, `previous_revision_id`); if two drafts based on the same revision are finalized, the first wins
- `first_round` is at most `last_round`. The first revision starts at round 1
- A revision is either an **extension** (`first_round` is one past the contest's current last round) or a **tail redraw** (`first_round` is at or before the current last round, and it replaces every round from `first_round` to the end of the contest). A tail redraw requires that no round from `first_round` onward has an accepted score
- Every round in a revision uses the same number of groups, `draw_config.groups_per_round`. This number may differ from earlier rounds only in an extension or a tail redraw. A redraw that does not reach the end of the contest must keep the number of groups of the rounds it replaces
- `groups_per_round` is a draw parameter chosen when the draw is made, not an editable contest configuration value. It must satisfy 1 ≤ G ≤ N, and when team protection is on, G is at least the largest number of pilots on any one team. The draw is rejected otherwise. Fewer than two pilots per group is a warning
- In seeded mode after the preliminary block, each revision draws exactly one round (`first_round` equals `last_round`) and requires every earlier round to be complete: every current assignment has an official score and no review request is open
- Group sizes are derived from the pilot count N and G; they are never stored
- The matrix-affecting contest configuration options are team protection, draw mode, and `preliminary_rounds`. Their values are copied verbatim into `draw_config` (draw mode as `configured_draw_mode`). When the current configuration differs from the latest finalized revision's `draw_config`, the app warns the director and offers a redraw of the unscored rounds. A difference never alters existing assignments
- The draw is reproducible: identical `draw_inputs`, `draw_config`, `random_seed`, `algorithm_version`, and prior history must produce the identical matrix on every platform. Prior history means the current assignments of earlier rounds as of `created_at`, which can be rebuilt because assignments are append-only
- `draw_inputs` is a historical snapshot, so the participation ids it holds are not enforced as foreign keys
- Only participations with the pilot role and an active status are included in the draw
- The current matrix is the set of current rounds (those neither superseded nor cancelled) and their current assignments across finalized revisions. Draft revisions never contribute to it
- A draft that is never finalized is simply abandoned; it has no effect on the current matrix

## Lifecycle

1. **Draft:** created by a draw. Its rounds and assignments exist but are internal, and no score placeholders exist yet.
2. **Finalized:** a director or assistant finalizes it. In one transaction: `finalized_by` and `finalized_at` are set, its rounds become current, any rounds it replaces are marked superseded, ordinals it leaves uncovered are cancelled, and a score placeholder is created for each `Original` assignment.
3. A finalized revision is immutable. Later changes to the matrix are new revisions, or `Moved`, `Reflight`, and late-add assignment rows.

## Privacy and Scope

- Internal to contest management. The seed, algorithm version, draw inputs, fairness summary, and reason are private to organizers
- The matrix layout (rounds, groups, lanes) becomes visible to participants and the public once the revision is finalized

## Audit and Synchronization

- A revision is immutable once created, except for the single write-once finalization (`finalized_by`, `finalized_at`)
- Creating and finalizing a revision each record an AuditEvent
- Two clients finalizing at the same time are resolved first-write-wins through the standard conflict process
- Draws are deterministic, so a duplicate draw created offline can be detected by comparing inputs, configuration, seed, and engine version
- Idempotent: re-querying the latest finalized revision always returns the same revision
