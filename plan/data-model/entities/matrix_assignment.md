# MatrixAssignment

**Relationship to architecture-requirements:** `plan/architecture-requirements/data/matrix-and-assignments.md`
**Purpose:** Records a pilot's scheduled and credited round, group, and lane within a draw, including the reason for assignment, type, and actor. Scheduled and credited rounds are separated so a re-flight can receive credit for the original round without rewriting history.
**Identifier:** `assignmentId` (UUIDv7)
**Parent entity:** MatrixRevision
**Child entities:** ScorePlaceholder

## Relationships
Belongs to a MatrixRevision (FK: `matrixRevisionId`); references a ContestParticipation (FK: `linkId_part`); parent of ScorePlaceholder (one-to-one); referenced by Score and ReFlight (FK: `assignmentId`).

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `assignmentId` | UUIDv7 | Yes | - | Primary key |
| `matrixRevisionId` | UUID | Yes | - | FK to MatrixRevision |
| `linkId_part` | UUID | Yes | - | FK to ContestParticipation (pilot link) |
| `scheduledRound` | Int | Yes | - | Round number the pilot is scheduled to fly |
| `creditedRound` | Int | Yes | - | Round number for which the pilot receives credit |
| `group` | Int | Yes | - | Group number assigned |
| `lane` | Int | Yes | - | Lane number assigned |
| `assignmentType` | Enum(Original, Moved, Reflight) | Yes | Original | How this assignment was generated |
| `sourceAssignmentId` | UUID | No | - | FK to the prior assignment this replaced |
| `flightSequence` | Enum(First, Second) | No | - | If re-flight, which sequence is this |
| `assignmentRevision` | Int | No | 0 | Incremental revision number |
| `actor` | UUID | No | - | FK to Agent who created or modified |
| `reason` | String | No | - | Explanation for the assignment or move |
| `created_at` | DateTime | Yes | now() | Created ts |
| `updated_at` | DateTime | Yes | now() | Updated ts |

## Invariants and Constraints
- A score placeholder exists for every pilot assignment, even before a value is entered.
- A scored assignment cannot be silently moved or reinterpreted.
- An assignment is immutable once its Score is recorded; subsequent changes create a new assignment with incremented `assignmentRevision` and `sourceAssignmentId` pointing to the original.
- Scheduled and credited rounds are separate so a later re-flight can receive credit for the original round without rewriting history.

## Lifecycle
Created (Original) → [Modified → Moved/Reflight] → Scored → Finalized. Once a Score is entered, the assignment locks.

## Privacy and Scope
Visible to all contestants and organizers. Move reasons and actor are kept private to reduce controversy.

## Audit and Synchronization
Create and read operations are idempotent. Move and Reflight operations are additive; each change generates a new assignment entry. Rollbacks are not supported. Audit trail: every move or re-flight references the previous assignment via `sourceAssignmentId`.