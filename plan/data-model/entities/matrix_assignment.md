# MatrixAssignment

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md, plan/architecture-requirements/data/matrix-draw.md
**Purpose:** Places one pilot participation into a group and lane for a flight in a round. Assignments are append-only history: a draw creates `Original` rows, a move creates a `Moved` row that supersedes its source, and a re-flight creates a `Reflight` row. Scheduled and credited rounds are separate so a move or re-flight can receive credit for the original round without rewriting history.
**Identifier:** `id` (UUIDv7)
**Parent entity:** MatrixRevision
**Child entities:** ScorePlaceholder (exactly one per assignment)

## Relationships

- Belongs to MatrixRevision (the revision that contains its scheduled round)
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Belongs to a ContestParticipation (a pilot)
- References a Round as the scheduled round (`scheduled_round_id`) and a Round as the credited round (`credited_round_id`)
- References a source MatrixAssignment (`source_assignment_id`) for `Moved` and `Reflight` rows
- References the ReFlight that created it (`re_flight_id`) for `Reflight` rows
- Owns exactly one ScorePlaceholder, which exists from creation even before a score is entered

## Fields/Properties

| Field                         | Type      | Required    | Default | Description                                                                                                       |
| ----------------------------- | --------- | ----------- | ------- | ----------------------------------------------------------------------------------------------------------------- |
| `id`                          | UUIDv7    | Yes         | -       | Stable identity                                                                                                   |
| `contest_id`                  | UUIDv7    | Yes         | -       | FK Contest (denormalized; must match the contests of the matrix revision, rounds, and participation)              |
| `matrix_revision_id`          | UUIDv7    | Yes         | -       | FK MatrixRevision; must be the revision that contains the scheduled round                                         |
| `contest_participation_id`    | UUIDv7    | Yes         | -       | FK ContestParticipation; must be an active participation with the pilot role                                      |
| `scheduled_round_id`          | UUIDv7    | Yes         | -       | FK Round in which the flight is flown                                                                             |
| `credited_round_id`           | UUIDv7    | Yes         | -       | FK Round the flight's score counts toward                                                                         |
| `group`                       | int       | Yes         | -       | Group number within the scheduled round                                                                           |
| `lane`                        | int       | Yes         | -       | Lane (flight line station) within the group                                                                       |
| `flight_sequence`             | int       | Yes         | 1       | Flight sequence for this participation within the credited round; re-flights take the next sequence number        |
| `assignment_type`             | enum      | Yes         | -       | `Original`, `Moved`, or `Reflight`                                                                                |
| `source_assignment_id`        | UUIDv7    | Conditional | -       | FK MatrixAssignment this row moves or re-flies; required for `Moved` and `Reflight`, null for `Original`          |
| `re_flight_id`                | UUIDv7    | Conditional | -       | FK ReFlight that created this row; required for `Reflight`, null otherwise                                        |
| `superseded_by_assignment_id` | UUIDv7    | No          | -       | FK MatrixAssignment (`Moved` row) that replaced this one. Write-once; the only column ever updated after creation |
| `actor_id`                    | UUIDv7    | Yes         | -       | FK; person or authority who created the row (the draw's creator for `Original`)                                   |
| `reason`                      | string    | Conditional | -       | Why the row was created; required for `Moved` and `Reflight`                                                      |
| `created_at`                  | timestamp | Yes         | -       | When the row was created (server time)                                                                            |

## Invariants and Constraints

- Append-only: rows are never modified, except that `superseded_by_assignment_id` is set once when a move replaces the row
- **Original:** no source, no re-flight, `credited_round_id` equals `scheduled_round_id`, `flight_sequence` is 1
- **Moved:** the source must belong to the same participation and be unscored (its placeholder is `NotEntered`); `credited_round_id` and `flight_sequence` are copied from the source; `group`, `lane`, and `scheduled_round_id` may differ, and the scheduled round must be current. Creating the row sets the source's `superseded_by_assignment_id`
- **Reflight:** the source must belong to the same participation; `credited_round_id` equals the source's; `flight_sequence` is the next unused sequence for that participation and credited round; the scheduled round must be current. A re-flight does not supersede its source; which score counts for the round follows the discipline's result-selection rules
- A scored assignment cannot be moved, silently or otherwise
- `matrix_revision_id` and `contest_id` must match the scheduled round's matrix revision and contest (enforce with a composite FK on the round); the credited round must belong to the same contest
- `group` is between 1 and the scheduled round's `group_count`; `lane` is between 1 and the largest group size of that round
- A lane in a group is occupied by at most one current assignment: (`scheduled_round_id`, `group`, `lane`) is unique among rows where `superseded_by_assignment_id` is null
- A pilot has at most one current `Original` or `Moved` assignment per credited round: (`contest_participation_id`, `credited_round_id`) is unique among such rows where `superseded_by_assignment_id` is null
- When team protection is enabled, no two pilots from the same team share a (`scheduled_round_id`, `group`) among current assignments; the draw guarantees this and moves must preserve it
- Only participations with the pilot role and an active status appear in assignments
- An assignment is current when `superseded_by_assignment_id` is null and its scheduled round is current (its `superseded_by_round_id` is null). Non-current assignments, and their placeholders, are excluded from missing-score checks, round completeness, the seeded-draw prerequisite, and standings

## Lifecycle

- `Original` rows are created in bulk when a matrix revision is drawn.
- A `Moved` row is created when a director moves an unscored pilot to a different group, lane, or round slot.
- A `Reflight` row is created when a re-flight is finalized.
- Rows are never deleted. Moved-away rows remain as history and are marked superseded. Rows in a superseded round simply stop being current.

## Privacy and Scope

- Internal to contest administration while the matrix revision is a draft
- Once the revision is finalized, current assignments are part of the published flight schedule visible to participants and the public

## Audit and Synchronization

- Mutations: creation, plus the single write-once supersession update
- Every creation records an AuditEvent with the actor, authority, and reason. For a move, the source row holds the previous group, lane, and round slot
- Offline moves that collide on a lane are resolved through the standard conflict process, since the unique constraint rejects the second write
- Each assignment has exactly one ScorePlaceholder, created in the same transaction
