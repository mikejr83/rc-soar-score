# ReviewRequest

**Relationship to architecture-requirements:** plan/architecture-requirements/data/reviews-and-invitations.md  
**Purpose:** Captures a participant's proposed revised score while preserving the original score for comparison. It cannot be submitted on a score marked Official or Locked. Approving it creates a new official revision; it never changes the original submission.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** ScorePlaceholder  
**Child entities:** None

## Relationships

- Belongs to a ScorePlaceholder (`score_placeholder_id`) and to a Contest (`contest_id`, denormalized for sync scoping and authorization)
- One-to-many: several review requests over time for the same score
- References the ScoreAttempt created when it is approved (`resulting_attempt_id`)
- Reference only: a review request proposes a new score without changing the original score submission

## Fields/Properties

| Field                  | Type                   | Required | Default   | Description                                                           |
| ---------------------- | ---------------------- | -------- | --------- | --------------------------------------------------------------------- |
| `id`                   | UUIDv7                 | Yes      | -         | Primary key identifying the review request                            |
| `contest_id`           | UUIDv7                 | Yes      | -         | FK Contest (denormalized; must match the placeholder's contest)       |
| `score_placeholder_id` | UUIDv7                 | Yes      | -         | FK to the ScorePlaceholder being reviewed                             |
| `proposed_components`  | Map of Component/Value | Yes      | -         | JSON object mapping each scoring component to its proposed value      |
| `participant_message`  | String                 | No       | null      | Optional message shared with the director                             |
| `requester_id`         | UUIDv7                 | Yes      | -         | FK Account of the participant who made the request                    |
| `base_score_revision`  | Integer                | Yes      | -         | Score revision number at the time of the request                      |
| `requested_at`         | timestamptz            | Yes      | -         | Time the review request was submitted                                 |
| `state`                | Enum                   | Yes      | Submitted | `Submitted`, `UnderReview`, `Approved`, `Rejected`, or `Superseded`   |
| `decision_actor_id`    | UUIDv7                 | No       | null      | FK Account that rendered the decision                                 |
| `decision_time`        | timestamptz            | No       | null      | Time the decision was made                                            |
| `decision_message`     | String                 | No       | null      | Rationale for the decision                                            |
| `resulting_attempt_id` | UUIDv7                 | No       | null      | FK ScoreAttempt created when the request was approved. Null otherwise |
| `revision`             | Integer                | Yes      | 0         | Row-level sync counter, incremented on every change                   |

## Invariants and Constraints

- Cannot be submitted on a score marked Official or locked at the score, group, round, or contest level
- At most one review request is open (`Submitted` or `UnderReview`) per score placeholder
- `proposed_components` must be consistent with the score calculation rules for the flight
- `proposed_components` must not include `cumulative_penalty`; only the director applies it
- `decision_actor_id`, `decision_time`, and `resulting_attempt_id` are null while the state is `Submitted`
- Approval creates a ScoreAttempt under director authority that carries the proposed components, and a new OfficialScore version that cites it. The original submission is never changed
- If an official edits or marks a score official while a review is pending, the review is superseded. Superseded reviews are not processed and stay `Superseded`
- If the underlying official score changed after the request's base revision, the director must explicitly approve, reject, or supersede it. It is never applied or rejected automatically
- `contest_id` must equal the contest of the referenced placeholder

## Lifecycle

```plaintext
Submitted -> UnderReview
UnderReview -> Approved (new official revision)
UnderReview -> Rejected (message shared with the participant)
Submitted | UnderReview -> Superseded (if an official edits the score or marks it official)
```

## Privacy and Scope

- `participant_message` is shared with the director
- `decision_message` rationale may be private to officials
- Review state and decisions are shared within the contest context
- Original score values are visible to all contest participants

## Audit and Synchronization

- Creating a review request is audited as `ScoreReview`, and every state transition is audited
- `base_score_revision` supports optimistic locking on the score
- If a score is superseded, its pending reviews are also superseded
- Approved reviews create a score revision through separate audit entries
