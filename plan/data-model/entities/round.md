# Round

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md, plan/architecture-requirements/data/matrix-draw.md  
**Purpose:** A numbered round of flights within a matrix revision. Records the round's number, its group count, and its lock status. It is the anchor for round-level locks, for the seeded-draw prerequisite ("all earlier rounds complete"), and for per-round reporting. Replaces the former RoundConfig entity.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** MatrixRevision  
**Child entities:** RoundGroup, MatrixAssignment (references a round through `scheduled_round_id` and `credited_round_id`)

## Relationships

- Belongs to MatrixRevision (the draw that created it)
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Referenced by MatrixAssignment as the scheduled round (where the flight is flown) and as the credited round (where the score counts)
- May be superseded by a round with the same ordinal in a later MatrixRevision, or cancelled, but only while it has no accepted scores (`superseded_by_round_id`, `Cancelled` status)

## Fields/Properties

| Field                    | Type   | Required | Default | Description                                                                       |
| ------------------------ | ------ | -------- | ------- | --------------------------------------------------------------------------------- |
| `id`                     | UUIDv7 | Yes      | -       | Stable identity                                                                   |
| `contest_id`             | UUIDv7 | Yes      | -       | FK Contest (denormalized; must match the matrix revision's contest)               |
| `matrix_revision_id`     | UUIDv7 | Yes      | -       | FK MatrixRevision that created this round                                         |
| `ordinal`                | int    | Yes      | -       | Round number within the contest, starting at 1                                    |
| `group_count`            | int    | Yes      | -       | Number of groups (G) in this round                                                |
| `status`                 | enum   | Yes      | Open    | Round status: `Open`, `Locked`, or `Cancelled`                                    |
| `superseded_by_round_id` | UUIDv7 | No       | -       | FK Round (same ordinal, later matrix revision) that replaced this one. Write-once |
| `revision`               | int    | Yes      | 0       | Row-level sync counter, incremented when `status` changes                         |

## Invariants and Constraints

- (`matrix_revision_id`, `ordinal`) is unique
- (`contest_id`, `ordinal`) is unique among rounds that are neither superseded (`superseded_by_round_id` is null) nor `Cancelled`, so each ordinal has at most one current round
- `ordinal` falls within the matrix revision's `first_round` to `last_round` range
- `group_count` is at least 1 and counts only the regular groups made by the draw. Re-flight groups are extra groups numbered after them, and are recorded on the ReFlight rather than here
- When team protection is enabled, `group_count` must be at least the largest number of pilots on any one team; the draw rejects the configuration otherwise
- Group sizes are derived, not stored: with N pilots and G groups, exactly N mod G groups hold floor(N/G) + 1 pilots and the rest hold floor(N/G). Lane count is the contest option `lane_count`, which defaults to the size of the largest group
- A round with any accepted score cannot be superseded. Rounds with new ordinals may be added at any time under the contest lifecycle rules
- `superseded_by_round_id` is set once, in the same transaction that finalizes the replacing matrix revision. The replacing round must have the same ordinal and contest
- When a round is superseded or cancelled, all assignments scheduled in it stop being current without any per-assignment update
- Group capacity for late additions is derived: the largest group size of the round's original draw, `ceil(N / G)` with N the count of the round's `Original` assignments. It does not change when pilots are added later
- A pilot with no current assignment credited to a round does not affect that round's completeness. The round counts for that pilot as not entered in the calculation
- Completeness is derived, not stored: a round is complete when every current assignment credited to it has an official score (including official zero and retired outcomes) and no review request is open
- While `Locked`, score entry and assignment moves for the round are rejected unless the contest director overrides with a recorded reason. Creating an assignment credited to a locked round is rejected too. The round's groups are locked or unlocked individually through RoundGroup; a score is locked if its own lock, its group, this round, or the contest is locked
- A round becomes `Cancelled` when a tail redraw shrinks the contest and leaves its ordinal uncovered, or when the director drops an unflown round. Only a round with no accepted scores can be cancelled; cancellation is terminal and audited
- A cancelled round is not current: its assignments and their placeholders are excluded from missing-score checks, round completeness, the seeded-draw prerequisite, and standings
- `contest_id` must equal the contest of the referenced matrix revision

## Lifecycle

1. Created together with its matrix revision (rounds of a draft revision are internal).
2. Becomes current when the matrix revision is finalized.
3. `Open` and `Locked` can be toggled by the contest director, each change audited.
4. Superseded by a later revision, or `Cancelled`, only while unscored. Never deleted.

## Privacy and Scope

- Internal to contest administration while the matrix revision is a draft
- Round numbers and group counts are part of the published flight schedule once the revision is finalized

## Audit and Synchronization

- Mutations: creation with the matrix revision, `status` changes (lock, unlock, cancel), and the single write-once supersession update
- Each `status` change records an AuditEvent with the actor, reason, and base revision, and increments `revision`
- Superseded rounds are retained for history and reproducibility
