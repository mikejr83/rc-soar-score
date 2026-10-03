# OfficialScore

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md  
**Purpose:** Versioned authoritative score component set, selected per score placeholder. Distinct from immutable ScoreAttempt submissions.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ScorePlaceholder  
**Child entities:** None

## Relationships

- Belongs to ScorePlaceholder (one per version)
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Cited by ScoreCalculationResult
- Supersedes previous OfficialScore version for same placeholder
- Links back to the ScoreAttempt that produced it (the configuration and matrix revisions in effect at entry are reachable through that attempt)

## Fields/Properties

| Field                  | Type      | Required | Default | Description                                                                                                                                          |
| ---------------------- | --------- | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | UUIDv7    | Yes      | -       | Stable identity                                                                                                                                      |
| `contest_id`           | UUIDv7    | Yes      | -       | FK Contest (denormalized; must match the placeholder's contest)                                                                                      |
| `score_placeholder_id` | UUIDv7    | Yes      | -       | FK ScorePlaceholder                                                                                                                                  |
| `score_attempt_id`     | UUIDv7    | Yes      | -       | FK ScoreAttempt that produced this score                                                                                                             |
| `score_revision`       | int       | Yes      | -       | Revision number of this version                                                                                                                      |
| `components`           | JSON      | Yes      | -       | Authoritative input components: duration_sec, penalties, adjustments, zero reason. Calculated values (e.g. base score) belong in calculation results |
| `set_at`               | timestamp | Yes      | -       | When this score became official                                                                                                                      |
| `set_by`               | UUIDv7    | Yes      | -       | FK; person/authority who made it official                                                                                                            |
| `reason`               | string    | Yes      | -       | Explanation for selection                                                                                                                            |

## Invariants and Constraints

- Represents versioned output, not raw submission
- Multiple OfficialScore records exist per placeholder (version history)
- (`score_placeholder_id`, `score_revision`) is unique
- Each cites its source ScoreAttempt for traceability
- Latest score_revision for a placeholder is the current authoritative score
- Components normalized to standard units when appropriate
- A landing selection in `components` is the selected LandingResult id, which fixes the key, points, and table
- Components hold authoritative inputs only; values derived from the contest configuration are calculated and stored in ScoreCalculationResult, so retroactive configuration changes never leave stale values here
- `contest_id` must equal the contest of the referenced placeholder and attempt

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
