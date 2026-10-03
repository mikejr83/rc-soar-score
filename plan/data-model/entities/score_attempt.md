# ScoreAttempt

**Relationship to architecture-requirements:** plan/architecture-requirements/data/scores-and-results.md  
**Purpose:** Immutable canonical raw submission of score data for a pilot's score placeholder.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ScorePlaceholder  
**Child entities:** None

## Relationships

- Belongs to ScorePlaceholder
- Belongs to Contest (denormalized `contest_id` for sync scoping and authorization)
- References the ContestConfigurationRevision and MatrixRevision the client held when the entry was accepted
- Optionally references the Invitation under which the entry was submitted
- Captures original submission, every review proposal, superseded attempts, and current official set distinctly
- A director correction creates a new authorized official revision that never overwrites source history

## Fields/Properties

| Field                  | Type   | Required     | Default | Description                                                                                                                                                              |
| ---------------------- | ------ | ------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`                   | UUIDv7 | Yes          | -       | Stable identity                                                                                                                                                          |
| `contest_id`           | UUIDv7 | Yes          | -       | FK Contest (denormalized; must match the placeholder's contest)                                                                                                          |
| `score_placeholder_id` | UUIDv7 | Yes          | -       | FK ScorePlaceholder                                                                                                                                                      |
| `config_revision_id`   | UUIDv7 | Yes          | -       | FK ContestConfigurationRevision the client held when the entry was accepted ("entered under"). Informational: calculation always uses the current configuration revision |
| `matrix_revision_id`   | UUIDv7 | Yes          | -       | FK MatrixRevision the client held when the entry was accepted                                                                                                            |
| `raw_components`       | JSON   | Yes          | -       | Raw submitted components preserving original units                                                                                                                       |
| `actor_id`             | UUIDv7 | Yes          | -       | FK; identifies person/authority who submitted                                                                                                                            |
| `authority`            | enum   | Yes          | -       | `Director`, `Participant`, `Helper`, `System`, or `Administrator`. A local operator acts as `Director`                                                                   |
| `invitation_id`        | UUIDv7 | No           | -       | FK Invitation under which the entry was submitted                                                                                                                        |
| `source_device`        | string | No           | -       | Device/browser used                                                                                                                                                      |
| `client_mutation_id`   | string | Yes (unique) | -       | Client-side dedup key                                                                                                                                                    |
| `base_score_revision`  | int    | Yes          | -       | Score revision this attempt was based on                                                                                                                                 |

## Invariants and Constraints

- Immutable once created
- Never modify ScoreAttempt after first write (append-only)
- Score revision history kept at placeholder level, not per attempt
- Drafts/queued submissions are not accepted data: don't affect lifecycle/rankings/publication
- client_mutation_id must be unique for deduplication
- `raw_components` may include `cumulative_penalty` only on an attempt made under director authority (the director or a local operator). The service rejects a participant-authority attempt that includes it
- A landing selection in `raw_components` is stored as the selected LandingResult id. Landing tables never change, so the id fixes the key, the points, and the table the calculation used
- `contest_id` must equal the contest of the referenced placeholder, configuration revision, and matrix revision
- Contest configuration changes are retroactive: `config_revision_id` records what the client saw at entry time and does not pin how the score is later calculated

## Lifecycle

Created once, never modified (append-only)

## Privacy and Scope

- Internal to contest administration
- Part of audit trail for score determination

## Audit and Synchronization

- Captures original submission, every review proposal, and superseded attempts distinctly
- Director corrections create new attempts that never overwrite source history
- Mutations: creation only (append-only history)
- Idempotent creation guarded by client_mutation_id
