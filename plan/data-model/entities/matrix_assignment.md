# MatrixAssignment

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md, plan/architecture-requirements/data/matrix-draw.md  
**Purpose:** Places one pilot participation into a group and lane for a flight in a round. Assignments are append-only history: a draw creates `Original` rows, a move creates a `Moved` row that supersedes its source, and a re-flight creates a `Reflight` row, and a late addition creates a `LateAdd` row. Scheduled and credited rounds are separate so a move or re-flight can receive credit for the original round without rewriting history.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** MatrixRevision  
**Child entities:** ScorePlaceholder (one per finalized current assignment)

## Relationships

- Belongs to MatrixRevision (the revision that contains its scheduled round)
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Belongs to a ContestParticipation (a pilot)
- References a Round as the scheduled round (`scheduled_round_id`) and a Round as the credited round (`credited_round_id`)
- References a source MatrixAssignment (`source_assignment_id`) for `Moved` and `Reflight` rows. `Original` and `LateAdd` rows have none
- References the ReFlight that created it (`re_flight_id`) for `Reflight` rows
- Owns at most one ScorePlaceholder, which exists before any score is entered. It is created when the matrix revision is finalized (`Original` rows) or together with the row itself (`Moved` and `Reflight`); assignments in a draft revision have none

## Fields/Properties

| Field                         | Type      | Required    | Default | Description                                                                                                                                                                                                       |
| ----------------------------- | --------- | ----------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                          | UUIDv7    | Yes         | -       | Stable identity                                                                                                                                                                                                   |
| `contest_id`                  | UUIDv7    | Yes         | -       | FK Contest (denormalized; must match the contests of the matrix revision, rounds, and participation)                                                                                                              |
| `matrix_revision_id`          | UUIDv7    | Yes         | -       | FK MatrixRevision; must be the revision that contains the scheduled round                                                                                                                                         |
| `contest_participation_id`    | UUIDv7    | Yes         | -       | FK ContestParticipation; must be a pilot participation that has not retired                                                                                                                                       |
| `scheduled_round_id`          | UUIDv7    | Yes         | -       | FK Round in which the flight is flown                                                                                                                                                                             |
| `credited_round_id`           | UUIDv7    | Yes         | -       | FK Round the flight's score counts toward                                                                                                                                                                         |
| `group`                       | int       | Yes         | -       | Group number within the scheduled round                                                                                                                                                                           |
| `lane`                        | int       | No          | -       | Lane (flight line station) within the group. Null when the contest's lane mode is `None`                                                                                                                          |
| `flight_sequence`             | int       | Yes         | 1       | Flight sequence for this participation within the credited round; re-flights take the next sequence number                                                                                                        |
| `assignment_type`             | enum      | Yes         | -       | `Original`, `Moved`, `Reflight`, or `LateAdd`                                                                                                                                                                     |
| `source_assignment_id`        | UUIDv7    | Conditional | -       | FK MatrixAssignment this row moves or re-flies; required for `Moved` and `Reflight`, null for `Original` and `LateAdd`                                                                                            |
| `re_flight_id`                | UUIDv7    | Conditional | -       | FK ReFlight that created this row; required for `Reflight`, null otherwise                                                                                                                                        |
| `superseded_by_assignment_id` | UUIDv7    | No          | -       | FK MatrixAssignment (`Moved` row) that replaced this one. Write-once; the only column ever updated after creation                                                                                                 |
| `actor_id`                    | UUIDv7    | Yes         | -       | FK; person or authority who created the row (the draw's creator for `Original`)                                                                                                                                   |
| `reason`                      | string    | Conditional | -       | Why the row was created; required for `Moved`, `Reflight`, and `LateAdd`                                                                                                                                          |
| `existing_score_handling`     | enum      | Yes         | None    | `None` or `Reset`. `Reset` when a `Moved` row replaces an assignment that already has an accepted score: the old score stays in the history and stops counting, and the new assignment starts with an empty score |
| `reset_score_revision`        | int       | No          | -       | The `score_revision` of the replaced placeholder at the time of the reset. Null unless `existing_score_handling` is `Reset`                                                                                       |
| `created_at`                  | timestamp | Yes         | -       | When the row was created (server time)                                                                                                                                                                            |

## Invariants and Constraints

- Append-only: rows are never modified, except that `superseded_by_assignment_id` is set once when a move replaces the row. The one deletion: when a pilot with no scores is removed from the contest or changed to a non-flying role after the draw, their assignments (and their empty score placeholders) are deleted, each with a tombstone, and the matrix revision does not change. The draw then no longer includes the pilot and the director is told to redo it. A pilot with any score is never deleted this way; they retire. On sync the server accepts the deletion only from a director and only after the row's score slot is gone (a slot with attempts or scores cannot be deleted); it cannot check that the pilot is also being removed or demoted, because the client sends the row deletions before the participation change
- **Original:** no source, no re-flight, `credited_round_id` equals `scheduled_round_id`, `flight_sequence` is 1
- **Moved:** the source must belong to the same participation. `credited_round_id` and `flight_sequence` are copied from the source; `group`, `lane`, and `scheduled_round_id` may differ, and the scheduled round must be current. Creating the row sets the source's `superseded_by_assignment_id`. If the source already has an accepted score, the move is a **reset**: `existing_score_handling` is `Reset`, `reset_score_revision` records the cleared revision, and the new placeholder starts `NotEntered` so the pilot can enter the score again. The old placeholder keeps its attempts and official scores as history and is no longer counted. There is no transfer of a score between groups. A move to the same round, group, and lane is allowed only as a reset of a score entered in the wrong place; it supersedes the source in the same transaction, so the slot stays unique
- **LateAdd:** places a pilot who joined after the draw, or who is making up a missed round, in a group. No source and no re-flight. `credited_round_id` may differ from `scheduled_round_id`, and may be a round the pilot missed. `flight_sequence` is 1. The scheduled round must be current. The target group must have no accepted score, so a pilot cannot join a group that has already flown. The pilot must not already be in that group. The group must have an open spot (see below). A reason is required. A pilot may hold several `LateAdd` rows in the same scheduled round, in different groups, each credited to a different round
- **Reflight:** the source must belong to the same participation; `credited_round_id` equals the source's; `flight_sequence` is the next unused sequence for that participation and credited round; the scheduled round must be current. A re-flight does not supersede its source; which score counts for the round follows the discipline's result-selection rules
- A scored assignment can be moved only by an explicit director action that resets its score. The application never moves, transfers, or reinterprets a score silently. A move requires the source score and both groups to be unlocked, unless the director overrides with a recorded reason. An open review request on the source score is superseded by the move
- `matrix_revision_id` and `contest_id` must match the scheduled round's matrix revision and contest (enforce with a composite FK on the round); the credited round must belong to the same contest
- `group` is between 1 and the scheduled round's `group_count`, except that a `Reflight` row flies in its ReFlight's `flown_group`, which may be a re-flight group numbered after the regular groups; when the lane mode is `Random`, `lane` is between 1 and the largest group size of the scheduled round's original draw, and when it is `None`, `lane` is null
- (`scheduled_round_id`, `group`) must reference an existing RoundGroup (composite foreign key), so every assignment sits in a group that can be locked
- A lane in a group is occupied by at most one current assignment: (`scheduled_round_id`, `group`, `lane`) is unique among rows where `lane` is not null and `superseded_by_assignment_id` is null
- A pilot has at most one current `Original`, `Moved`, or `LateAdd` assignment per credited round: (`contest_participation_id`, `credited_round_id`) is unique among such rows where `superseded_by_assignment_id` is null
- **Open spot for a `LateAdd`:** only regular groups (numbered up to `group_count`) can take a late addition; a re-flight group never can. A group has an open spot when its current assignments, of every type, number fewer than the round's group capacity. The capacity is the largest group size of the round's original draw, `ceil(N / G)`, where N is the number of the round's `Original` assignments and G is its `group_count`. Late adds never grow a group beyond it. The capacity is fixed by the draw and does not grow when pilots are added
- When team protection is enabled, no two pilots from the same team share a (`scheduled_round_id`, `group`) among current assignments; the draw guarantees this and moves and late adds must preserve it
- Only participations with the pilot role and no `retired_at_round` receive new assignments
- An assignment is current when `superseded_by_assignment_id` is null, its scheduled round is current (neither superseded nor `Cancelled`), and, for a `Reflight` row, its ReFlight is not `Cancelled`. Non-current assignments, and their placeholders, are excluded from missing-score checks, round completeness, the seeded-draw prerequisite, and standings

## Lifecycle

- `Original` rows are created in bulk when a matrix revision is drawn.
- A `Moved` row is created when a director moves a pilot to a different group, lane, or round slot, or resets a score entered in the wrong place by moving the pilot to the same slot.
- A `Reflight` row is created when a re-flight is finalized.
- A `LateAdd` row is created when a pilot is added after the draw, or when the director schedules a make-up flight for a missed round. If no group in the remaining rounds has an open spot, the pilot is not added and the director is told that no group is available. The application may offer to redraw the later unscored rounds, but only the director decides. It never redraws on its own, because printed matrix cards for the redrawn rounds would have to be reprinted. Cards for rounds that are not redrawn stay valid
- Rows are never deleted. Moved-away rows remain as history and are marked superseded. Rows in a superseded round simply stop being current.

## Privacy and Scope

- Internal to contest administration while the matrix revision is a draft
- Once the revision is finalized, current assignments are part of the published flight schedule visible to participants and the public

## Audit and Synchronization

- Mutations: creation, plus the single write-once supersession update
- Every creation records an AuditEvent with the actor, authority, and reason. For a move, the source row holds the previous group, lane, and round slot, and a reset also records the score revision that was cleared
- Offline moves that collide on a lane are resolved through the standard conflict process, since the unique constraint rejects the second write
- Placeholders are created in the transaction that finalizes the matrix revision (`Original` rows) or that creates the row (`Moved`, `Reflight`), so a finalized current assignment always has exactly one
