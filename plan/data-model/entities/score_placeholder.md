# ScorePlaceholder

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md  
**Purpose:** Reservation slot for the score of one pilot assignment. It exists before any value is entered, so every current assignment has a place for its score, attempts, reviews, and penalties. Its `state` is a denormalized summary of the score workflow; the facts live in its attempts, review requests, and official scores.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** MatrixAssignment  
**Child entities:** ScoreAttempt, OfficialScore, ReviewRequest, ContestPenalty

## Relationships

- Belongs to exactly one MatrixAssignment. Round, group, lane, and flight sequence are read from the assignment and are not stored here
- Belongs to a ContestParticipation (the pilot) and to a Contest (denormalized for sync scoping and authorization)
- Owns many ScoreAttempt instances (immutable submissions, including review proposals and superseded attempts)
- Owns many OfficialScore instances (versioned authoritative scores)
- Owns many ReviewRequest instances
- Referenced by ContestPenalty as the flight during which a contest penalty was incurred
- ScoreCalculationResult is derived from the placeholder's current OfficialScore and does not hang off the placeholder directly

## Fields/Properties

| Field                      | Type   | Required | Default    | Description                                                                                                               |
| -------------------------- | ------ | -------- | ---------- | ------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7 | Yes      | -          | Stable identity                                                                                                           |
| `contest_id`               | UUIDv7 | Yes      | -          | FK Contest (denormalized; must match the assignment's contest)                                                            |
| `contest_participation_id` | UUIDv7 | Yes      | -          | FK ContestParticipation; must match the assignment's participation                                                        |
| `assignment_id`            | UUIDv7 | Yes      | -          | FK MatrixAssignment this placeholder scores. Never changes after creation                                                 |
| `state`                    | enum   | Yes      | NotEntered | Summary of the score workflow: `NotEntered`, `Submitted`, `InReview`, or `Official`                                       |
| `score_revision`           | int    | Yes      | 0          | Counter of accepted score mutations: incremented each time an attempt is accepted or an official score version is created |
| `revision`                 | int    | Yes      | 0          | Row-level sync counter, incremented on any change to the row, including state changes that are not score mutations        |

## Invariants and Constraints

- `assignment_id` is unique: one placeholder per assignment
- (`assignment_id`, `contest_participation_id`) must match the assignment's own id and participation (composite FK), and `contest_id` must equal the assignment's contest
- A placeholder exists for every current assignment of a finalized matrix revision, regardless of whether a value has been entered. Assignments in a draft revision have none
- Placeholders are created when the matrix revision is finalized (for `Original` assignments) or together with the assignment row (for `Moved` and `Reflight`)
- Placeholders of assignments that are no longer current (moved away, in a superseded or cancelled round) are retained and stay `NotEntered`. They are excluded from missing-score checks, round completeness, and standings
- `state` is derived from the facts, in priority order:
  1. `InReview` if any review request is open
  2. `Official` if an official score exists
  3. `Submitted` if an accepted attempt exists
  4. `NotEntered` otherwise
- `state` is updated in the same transaction as the fact that changes it (accepting an attempt, opening or deciding a review request, creating an official score). It is never written directly by clients
- When an official score is created, the placeholder's `score_revision` is incremented and the new OfficialScore takes that value as its own `score_revision`, so (`score_placeholder_id`, `score_revision`) stays unique on OfficialScore, with gaps wherever attempts were accepted in between. An attempt's `base_score_revision` records the value the client had; a stale base is flagged for handling through the standard conflict process, never silently dropped
- `Draft` is not a state: drafts and queued submissions are local to the client and are not accepted data
- Zero, retired, and did-not-launch outcomes are not states. They are recorded as the official score's components (including the zero reason) and the placeholder is `Official`. A system-generated outcome (for example a no-show) enters through an attempt with system authority, so it follows the same path
- Whether a score counts as dropped is a calculation result, not placeholder state, because the dropped-rounds rule depends on the contest configuration, which can change
- While the assignment's scheduled round is `Locked`, or the contest is locked, score entry and review changes are rejected unless the contest director overrides with a recorded reason. Group-level and assignment-level locks are not modeled

## Lifecycle

```plaintext
NotEntered -> Submitted -> Official
Submitted  -> InReview  -> Submitted | Official
Official   -> InReview  -> Official
```

- A newly accepted attempt moves `NotEntered` to `Submitted`; later attempts keep it `Submitted` until a score is made official.
- Making a score official creates a new OfficialScore version. Director corrections create further versions, and the placeholder stays `Official`.
- Opening a review request moves it to `InReview`. Deciding the request returns it to `Official` if an official score exists, or to `Submitted` if not.
- Placeholders are never deleted.

## Privacy and Scope

- Internal to contest organization until publication
- Participants and the public see the latest OfficialScore once it exists. Visibility follows the publication rules and the existence of an official score, not the placeholder's `state`, so a score under review continues to show its last official value

## Audit and Synchronization

- Mutations are side effects of accepting an attempt, opening or deciding a review request, or creating an official score. Each is recorded through the triggering entity's AuditEvent and MutationRecord
- `score_revision` increments only on accepted attempts and new official score versions. `revision` increments on every change to the row
- Clients treat the placeholder as a server-owned summary: they submit attempts and review requests, and the state is recomputed when those are accepted
