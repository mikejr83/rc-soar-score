# ReFlight

**Relationship to architecture-requirements:** `plan/architecture-requirements/data/matrix-and-assignments.md`
**Purpose:** Records the lifecycle of a re-flight contest decision, including the credited round, awarding participants, director's final decision, and versioning of discipline/rules/calculation data at the time of the decision.
**Identifier:** `reflightId` (UUIDv7)
**Parent entity:** Contest
**Child entities:** None (leaf entity, references other entities only)

## Relationships
Belongs to a Contest (FK: `contestId`); referenced by MatrixAssignment (FK: `assignmentId`) for assignments of type Reflight.

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `reflightId` | UUIDv7 | Yes | - | Primary key |
| `contestId` | UUID | Yes | - | FK to Contest |
| `creditedRound` | Int | Yes | - | Round whose score is affected |
| `type` | String | No | - | Reason code or category for the re-flight |
| `sequence` | Int | Yes | 0 | Incremental sequence number (0 = first re-flight of a round) |
| `lifecycleStatus` | Enum(Open, Awarded, Finalized) | Yes | Open | Current status |
| `reason` | String | Yes | - | Director's explanation |
| `disciplineVersion` | Semver | Yes | 1.0.0 | Discipline profile version in use |
| `rulesVersion` | Semver | Yes | 1.0.0 | Rules version at time of decision |
| `calculationVersion` | Semver | Yes | 1.0.0 | Calculation engine version at time of decision |
| `creatingActor` | UUID | Yes | - | FK to Agent who opened the re-flight |
| `finalizingActor` | UUID | Yes | - | FK to Agent who finalized it |
| `awardedPilots` | Array[UUID] | Yes | - | Link IDs that received award |
| `drawCandidates` | Array[UUID] | No | - | Link IDs considered for the next draw |
| `drawExclusions` | Array[UUID] | No | - | Link IDs excluded |
| `selectedPilots` | Array[UUID] | No | - | Link IDs that will re-fly |
| `participantResponses` | Array[JSON] | No | - | Response records from pilot participants |
| `notifications` | Array[JSON] | No | - | Notification history |
| `directorDecision` | JSON | No | - | Director's final decision payload |

## Invariants and Constraints
- The discipline profile defines group-size, normalization, and result-selection rules; these are not generic contest fields.
- A re-flight is immutable once `lifecycleStatus` is Finalized.
- The re-flight `sequence` must be unique per `contestId` + `creditedRound` pair (i.e., only one first re-flight, only one second re-flight, etc.).

## Lifecycle
Open → Awarded → Finalized. While Open, the Director can make changes. Once Awarded, it is read-only except for the finalization step.

## Privacy and Scope
Participant responses and draw internal data are private to competitors. Director decisions, awarding, and final re-flight outcomes are public.

## Audit and Synchronization
Mutations are limited to the Open state. Once Awarded, no further changes are allowed. Idempotent operations: reading lifecycle state multiple times in parallel after Finalized returns the same result. All mutations require a server-side transaction to ensure consistency across the related assignments and draws.