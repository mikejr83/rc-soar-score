# Round

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md, plan/architecture-requirements/data/matrix-draw.md
**Purpose:** A numbered round of flights within a matrix revision. Records the round's number, its group count, and its lock status. It is the anchor for round-level locks, for the seeded-draw prerequisite ("all earlier rounds complete"), and for per-round reporting. Replaces the former RoundConfig entity.
**Identifier:** `id` (UUIDv7)
**Parent entity:** MatrixRevision
**Child entities:** MatrixAssignment (references a round through `scheduled_round_id` and `credited_round_id`)

## Relationships

- Belongs to MatrixRevision (the draw that created it)
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Referenced by MatrixAssignment as the scheduled round (where the flight is flown) and as the credited round (where the score counts)
- May be superseded by a round with the same ordinal in a later MatrixRevision, but only while it has no accepted scores (`superseded_by_round_id`)

## Fields/Properties

| Field                    | Type   | Required | Default | Description                                                                       |
| ------------------------ | ------ | -------- | ------- | --------------------------------------------------------------------------------- |
| `id`                     | UUIDv7 | Yes      | -       | Stable identity                                                                   |
| `contest_id`             | UUIDv7 | Yes      | -       | FK Contest (denormalized; must match the matrix revision's contest)               |
| `matrix_revision_id`     | UUIDv7 | Yes      | -       | FK MatrixRevision that created this round                                         |
| `ordinal`                | int    | Yes      | -       | Round number within the contest, starting at 1                                    |
| `group_count`            | int    | Yes      | -       | Number of groups (G) in this round                                                |
| `status`                 | enum   | Yes      | Open    | Lock status: `Open` or `Locked`                                                   |
| `superseded_by_round_id` | UUIDv7 | No       | -       | FK Round (same ordinal, later matrix revision) that replaced this one. Write-once |
| `revision`               | int    | Yes      | 0       | Row-level sync counter, incremented when `status` changes                         |

## Invariants and Constraints

- (`matrix_revision_id`, `ordinal`) is unique
- (`contest_id`, `ordinal`) is unique among rounds where `superseded_by_round_id` is null, so each ordinal has exactly one current round
- `ordinal` falls within the matrix revision's `first_round` to `last_round` range
- `group_count` is at least 1
- When team protection is enabled, `group_count` must be at least the largest number of pilots on any one team; the draw rejects the configuration otherwise
- Group sizes are derived, not stored: with N pilots and G groups, exactly N mod G groups hold floor(N/G) + 1 pilots and the rest hold floor(N/G). Lane count is the size of the largest group
- A round with any accepted score cannot be superseded. Rounds with new ordinals may be added at any time under the contest lifecycle rules
- `superseded_by_round_id` is set once, in the same transaction that finalizes the replacing matrix revision. The replacing round must have the same ordinal and contest
- When a round is superseded, all assignments scheduled in it stop being current without any per-assignment update
- Completeness is derived, not stored: a round is complete when every current assignment credited to it has an official score (including official zero and retired outcomes) and no review request is open
- While `Locked`, score entry and assignment moves for the round are rejected unless the contest director overrides with a recorded reason
- `contest_id` must equal the contest of the referenced matrix revision

## Lifecycle

1. Created together with its matrix revision (rounds of a draft revision are internal).
2. Becomes current when the matrix revision is finalized.
3. `Open` and `Locked` can be toggled by the contest director, each change audited.
4. Superseded by a later revision only while unscored. Never deleted.

## Privacy and Scope

- Internal to contest administration while the matrix revision is a draft
- Round numbers and group counts are part of the published flight schedule once the revision is finalized

## Audit and Synchronization

- Mutations: creation with the matrix revision, `status` changes, and the single write-once supersession update
- Each `status` change records an AuditEvent with the actor, reason, and base revision, and increments `revision`
- Superseded rounds are retained for history and reproducibility
