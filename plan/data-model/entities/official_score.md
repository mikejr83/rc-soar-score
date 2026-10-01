# OfficialScore

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md
**Purpose:** Versioned authoritative score component set, selected per score placeholder. Distinct from immutable ScoreAttempt submissions.
**Identifier:** `id` (UUIDv7)
**Parent entity:** ScorePlaceholder
**Child entities:** None

## Relationships

- Belongs to ScorePlaceholder (one per version)
- Cited by ScoreCalculationResult
- Supersedes previous OfficialScore version for same placeholder
- Links back to the ScoreAttempt that produced it

## Fields/Properties

| Field                | Type      | Required | Default | Description                                                                |
| -------------------- | --------- | -------- | ------- | -------------------------------------------------------------------------- |
| id                   | UUIDv7    | Yes      | -       | Stable identity                                                            |
| score_placeholder_id | UUIDv7    | Yes      | -       | FK ScorePlaceholder                                                        |
| score_revision       | int       | Yes      | -       | Revision number of this version                                            |
| components           | JSON      | Yes      | -       | Authoritative components: duration_sec, base_score, penalties, adjustments |
| score_attempt_id     | UUIDv7    | Yes      | -       | FK ScoreAttempt that produced this score                                   |
| set_at               | timestamp | Yes      | -       | When this score became official                                            |
| set_by               | UUIDv7    | Yes      | -       | Person/authority who made it official                                      |
| reason               | string    | Yes      | -       | Explanation for selection                                                  |

## Invariants and Constraints

- Represents versioned output, not raw submission
- Multiple OfficialScore records exist per placeholder (version history)
- Each cites its source ScoreAttempt for traceability
- Latest score_revision for a placeholder is the current authoritative score
- Components normalized to standard units when appropriate

## Lifecycle

Created when score made official. New version created on each officialization/score update. Old versions retained for history.

## Privacy and Scope

- Published to pilots and public once official
- Part of official contest results

## Audit and Synchronization

- Each version immutable
- New versions created by making score official, director corrections, or score updates
- Mutations: creation only (append-only version history)
- Idempotent creation guarded by score_revision counter
