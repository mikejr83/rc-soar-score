# ContestPenalty

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md
**Purpose:** Append-only record of a contest-long penalty assessed against a pilot by a contest administrator. Unlike a flight penalty (e.g. F3J late landing), which is part of the round score, a contest penalty follows the pilot for the entire contest and is never removed when a round score is dropped.
**Identifier:** `id` (UUIDv7)
**Parent entity:** ScorePlaceholder (the flight during which the penalty was incurred)
**Child entities:** None

## Relationships

- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- Assessed against a ContestParticipation
- Incurred during a ScorePlaceholder; the credited round is reachable through the placeholder's assignment
- May rescind another ContestPenalty (`rescinds_penalty_id`)
- Consumed by ScoreCalculationResult (participation standing) when computing the final contest score

## Fields/Properties

| Field                      | Type      | Required     | Default | Description                                                                                                                               |
| -------------------------- | --------- | ------------ | ------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7    | Yes          | -       | Stable identity                                                                                                                           |
| `contest_id`               | UUIDv7    | Yes          | -       | FK Contest (denormalized; must match the contest of the participation and placeholder)                                                    |
| `contest_participation_id` | UUIDv7    | Yes          | -       | FK ContestParticipation the penalty is assessed against                                                                                   |
| `score_placeholder_id`     | UUIDv7    | Yes          | -       | FK ScorePlaceholder of the flight during which the penalty was incurred                                                                   |
| `penalty_description`      | string    | Yes          | -       | Short label for the infraction, suitable for display (e.g. "Safety zone infraction")                                                      |
| `penalty_points`           | int       | Yes          | -       | Points to subtract, as a positive amount in the same units as scores. Must be greater than zero on an original penalty; 0 on a rescission |
| `assessed_by`              | UUIDv7    | Yes          | -       | FK; contest administrator who assessed the penalty                                                                                        |
| `authority`                | string    | Yes          | -       | Authority under which the penalty was assessed; must be an administrator authority                                                        |
| `reason`                   | string    | Yes          | -       | Director's justification for the audit trail. On a rescission row, explains why the penalty was withdrawn                                 |
| `assessed_at`              | timestamp | Yes          | -       | When the penalty was assessed (server time)                                                                                               |
| `rescinds_penalty_id`      | UUIDv7    | No           | -       | FK ContestPenalty being rescinded; set only on rescission rows                                                                            |
| `client_mutation_id`       | string    | Yes (unique) | -       | Client-side dedup key                                                                                                                     |

## Invariants and Constraints

- Only a contest administrator may create a ContestPenalty; the service rejects creation otherwise and records the authority on the row
- Append-only: never modified after creation
- `penalty_points` is greater than zero on original penalties and 0 on rescission rows
- A row with `rescinds_penalty_id` set is a rescission; it contributes no points of its own
- A penalty can be rescinded at most once: `rescinds_penalty_id` is unique
- A rescission cannot reference another rescission
- A rescission must belong to the same contest, participation, and placeholder as the penalty it rescinds
- Effective penalties are original penalties that have no rescission row
- `contest_id` must equal the contest of the referenced participation and placeholder, and the placeholder must belong to the same participation
- `client_mutation_id` must be unique for deduplication
- Penalty values are recorded as assessed; later configuration changes do not alter them

## Calculation Rules

- The pilot's contest penalty total is the sum of `penalty_points` over effective penalties for the participation
- The total is subtracted from the contest score after dropped rounds are applied, so a round being dropped never removes a contest penalty
- A penalty stays attached to the placeholder it was incurred on; superseding, re-flying, or dropping that round's score does not affect it
- Per-round reporting derives the round from the placeholder's credited round
- The derived total is stored with the participation standing in ScoreCalculationResult, not on any score row

## Lifecycle

Created when a contest administrator assesses a penalty. Withdrawn by appending a rescission row; the original is retained. Rows are never updated or deleted.

## Privacy and Scope

- Internal to contest administration
- Whether published results show the points, the description, or neither is not yet decided; the publication projection must follow that decision

## Audit and Synchronization

- Mutations: creation only (append-only history)
- Idempotent creation guarded by client_mutation_id
- Each creation, including rescissions, records an AuditEvent with the assessing actor and authority

## First-Release Scope

Penalties are free-form: the director enters a description and a points value. A comprehensive per-discipline penalty catalog is deferred. It can be added later with a nullable reference to a discipline penalty definition, keeping the free-text description as a fallback, without changing existing rows.
