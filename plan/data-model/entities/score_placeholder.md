# ScorePlaceholder

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md
**Purpose:** Reservation slot for the score of a pilot participating in a specific group and lane during a round's flight sequence. Exists for every pilot even before a value is entered.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Assignment
**Child entities:** ScoreAttempt, OfficialScore, ScoreCalculationResult

## Relationships
- Part of Participation for a round
- Owns many ScoreAttempt instances
- Owns many (versioned) OfficialScore instances
- Owns many ScoreCalculationResult instances

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUIDv7 | Yes | - | Stable identity |
| assignment_id | UUIDv7 | Yes | - | FK MatrixAssignment defining pilot/group/round/lane/sequence |
| contest_participation_id | UUIDv7 | Yes | - | FK ContestParticipation for round |
| group | string | Yes | - | Group identifier |
| lane | int | Yes | - | Lane of flight |
| flight_sequence | int | Yes | - | Flight sequence number; 0 = not launched |
| state | enum{NotEntered,Draft,Submitted,InReview,Official,Retired,Zero,Locked,Dropped} | Yes | NotEntered | Current state of placeholder |
| score_revision | int | Yes | 0 | Version counter for score-related mutations |

## Invariants and Constraints
- Exists for every pilot regardless of value entered
- state transitions follow defined flow: NotEntered → Draft → Submitted → InReview → Official, with Zero/Retired/Dropped/Locked as terminal alternatives
- Hierarchical lock order: Contest > Round > Group > Assignment > Score
- score_revision increments on any score-related mutation

## Lifecycle
NotEntered → Draft → Submitted → InReview → Official → Locked|Dropped
(From any state before Official: → Zero or → Retired)

## Privacy and Scope
- Internal to contest organization until publication
- Not shown to general public until Official state

## Audit and Synchronization
- State changes tracked via score_revision counter
- Mutated by submission, review, director decisions, system zero/retire logic