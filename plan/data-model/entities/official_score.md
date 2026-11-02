# OfficialScore

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md  
**Purpose:** Versioned authoritative score component set, selected per score placeholder. Distinct from immutable ScoreAttempt submissions.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ScorePlaceholder  
**Child entities:** None

## Relationships

- Belongs to ScorePlaceholder (one per version)
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Cited by FlightResult (`official_score_id`) as the version it was calculated from
- Supersedes previous OfficialScore version for same placeholder
- Links back to the ScoreAttempt that produced it (the configuration and matrix revisions in effect at entry are reachable through that attempt)

## Fields/Properties

| Field                  | Type      | Required | Default | Description                                                                                                                                       |
| ---------------------- | --------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                   | UUIDv7    | Yes      | -       | Stable identity                                                                                                                                   |
| `contest_id`           | UUIDv7    | Yes      | -       | FK Contest (denormalized; must match the placeholder's contest)                                                                                   |
| `score_placeholder_id` | UUIDv7    | Yes      | -       | FK ScorePlaceholder                                                                                                                               |
| `score_attempt_id`     | UUIDv7    | Yes      | -       | FK ScoreAttempt that produced this score                                                                                                          |
| `score_revision`       | int       | Yes      | -       | Revision number of this version                                                                                                                   |
| `components`           | JSON      | Yes      | -       | Authoritative input components: duration_sec, penalties, adjustments, zero reason. Calculated values (e.g. base score) are stored in FlightResult |
| `set_at`               | timestamp | Yes      | -       | When this score became official                                                                                                                   |
| `set_by`               | UUIDv7    | Yes      | -       | FK; person/authority who made it official                                                                                                         |
| `reason`               | string    | Yes      | -       | Explanation for selection                                                                                                                         |

## Invariants and Constraints

- Represents versioned output, not raw submission
- Multiple OfficialScore records exist per placeholder (version history)
- (`score_placeholder_id`, `score_revision`) is unique
- Each cites its source ScoreAttempt for traceability
- Latest score_revision for a placeholder is the current authoritative score
- Components normalized to standard units when appropriate
- `components` may include `flight_penalty`, a nullable non-negative integer deducted from the discipline raw score before the group score, so a dropped round drops it. Changing it is an official revision with a reason
- `components` may include `cumulative_penalty`, a nullable non-negative integer set only under director authority. Absent means no penalty was ever applied, a positive value is the points deducted, and zero means a penalty was applied and later removed. Changing it is an official revision with a reason, and earlier versions are kept
- A landing selection in `components` is the selected LandingResult id, which fixes the key, points, and table
- Components hold authoritative inputs only; values derived from the contest configuration are calculated and stored in FlightResult, so retroactive configuration changes never leave stale values here
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

### Bulk entry

The director's scoring page can save many rows at once (`POST /contests/{id}/scores/bulk`, up to 100 entries). Every entry is checked like a single one and refused alone if it fails. The accepted entries (attempt, official score, placeholder, the first-score contest change and correction audit of each) are stored in ONE transaction (`OfficialScoreRepository.recordEntries`); if a revision moved while storing, nothing of it is kept and the entries are stored one by one so only real conflicts are refused. The results are then recalculated once in their own transaction, and the public projection is updated at most once. A repeated request replays by each entry's `client_mutation_id`.
