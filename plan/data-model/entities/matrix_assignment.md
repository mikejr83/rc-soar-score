# MatrixAssignment

**Relationship to architecture-requirements:** `plan/architecture-requirements/data/matrix-and-assignments.md`
**Purpose:** Records a pilot's scheduled and credited round, group, and lane within a draw, including the reason for assignment, type, and actor. Scheduled and credited rounds are separated so a re-flight can receive credit for the original round without rewriting history.
**Identifier:** `id` (UUIDv7)
**Parent entity:** MatrixRevision
**Child entities:** ScorePlaceholder

## Relationships
Belongs to a MatrixRevision (FK: `matrix_revision_id`); references a ContestParticipation (FK: `contest_participation_id`); parent of ScorePlaceholder (one-to-one); referenced by Score and ReFlight (FK: `id`).

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | UUIDv7 | Yes | - | Primary key |
| `matrix_revision_id` | UUID | Yes | - | FK to MatrixRevision |
| `contest_participation_id` | UUID | Yes | - | FK to ContestParticipation (pilot link) |
| `scheduled_round` | Int | Yes | - | Round number the pilot is scheduled to fly |
| `credited_round` | Int | Yes | - | Round number for which the pilot receives credit |
| `group` | Int | Yes | - | Group number assigned |
| `lane` | Int | Yes | - | Lane number assigned |
| `assignment_type` | Enum(Original, Moved, Reflight) | Yes | Original | How this assignment was generated |
| `source_assignment_id` | UUID | No | - | FK to the prior assignment this replaced |
| `flight_sequence` | Enum(First, Second) | No | - | If re-flight, which sequence is this |
| `assignment_revision` | Int | No | 0 | Incremental revision number |
| `actor_id` | UUID | No | - | FK to Agent who created or modified |
| `reason` | String | No | - | Explanation for the assignment or move |
| `created_at` | DateTime | Yes | now() | Created ts |
| `updated_at` | DateTime | Yes | now() | Updated ts |

## Invariants and Constraints
- A score placeholder exists for every pilot assignment, even before a value is entered.
- A scored assignment cannot be silently moved or reinterpreted.
- An assignment is immutable once its Score is recorded; subsequent changes create a new assignment with incremented `assignment_revision` and `source_assignment_id` pointing to the original.
- Scheduled and credited rounds are separate so a later re-flight can receive credit for the original round without rewriting history.

## Lifecycle
Created (Original) → [Modified → Moved/Reflight] → Scored → Finalized. Once a Score is entered, the assignment locks.

## Privacy and Scope
Visible to all contestants and organizers. Move reasons and actor are kept private to reduce controversy.

## Audit and Synchronization
Create and read operations are idempotent. Move and Reflight operations are additive; each change generates a new assignment entry. Rollbacks are not supported. Audit trail: every move or re-flight references the previous assignment via `source_assignment_id`.