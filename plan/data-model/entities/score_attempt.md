# ScoreAttempt

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md
**Purpose:** Immutable canonical raw submission of score data for a pilot's score placeholder.
**Identifier:** `attemptId` (UUIDv7)
**Parent entity:** ScorePlaceholder
**Child entities:** None

## Relationships
- Belongs to ScorePlaceholder
- Captures original submission, every review proposal, superseded attempts, and current official set distinctly
- A director correction creates a new authorized official revision that never overwrites source history

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| attemptId | UUIDv7 | Yes | - | Stable identity |
| placeholderId | UUIDv7 | Yes | - | FK ScorePlaceholder |
| rawComponents | JSON | Yes | - | Raw submitted components preserving original units |
| cumulativePenalty | int | Yes | 0 | Running total of penalties applied |
| actorId | UUIDv7 | Yes | - | Identifies person/authority who submitted |
| authority | string | Yes | - | Organization/role of submitter |
| invitationReference | string | No | - | Reference number for invitation |
| sourceDevice | string | No | - | Device/browser used |
| clientMutationId | string | Yes (unique) | - | Client-side dedup key |
| baseScoreRevision | int | Yes | - | Score revision this attempt was based on |
| configRevision | int | Yes | - | Contest configuration revision |
| matrixRevision | int | Yes | - | Score matrix revision |
| disciplineRulesVersion | string | Yes | - | Version of discipline rules applied |
| calculationVersion | string | Yes | - | Version of calculation logic |

## Invariants and Constraints
- Immutable once created
- Never modify ScoreAttempt after first write (append-only)
- Score revision history kept at placeholder level, not per attempt
- Drafts/queued submissions are not accepted data: don't affect lifecycle/rankings/publication
- clientMutationId must be unique for deduplication

## Lifecycle
Created once, never modified (append-only)

## Privacy and Scope
- Internal to contest administration
- Part of audit trail for score determination

## Audit and Synchronization
- Captures original submission, every review proposal, and superseded attempts distinctly
- Director corrections create new attempts that never overwrite source history
- Mutations: creation only (append-only history)
- Idempotent creation guarded by clientMutationId