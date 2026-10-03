# ReviewRequest

**Relationship to architecture-requirements:** plan/architecture-requirements/data/reviews-and-invitations.md  
**Purpose:** Captures a score reviewer's proposed revised score while preserving the original score for comparison. Cannot be submitted on scores marked Official or Locked.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Score  
**Child entities:** None

## Relationships

- Belongs to a Score record (foreign key via `placeholder_id`)
- One-to-many: Multiple review requests over time for the same score
- Reference only: Review request proposes a new score without changing the original score submission

## Fields/Properties

| Field                 | Type                   | Required | Default   | Description                                                                     |
| --------------------- | ---------------------- | -------- | --------- | ------------------------------------------------------------------------------- |
| `id`                  | UUIDv7                 | Yes      | -         | Primary key identifying the review request                                      |
| `placeholder_id`      | UUIDv7                 | Yes      | -         | Foreign key to the Score being reviewed                                         |
| `proposed_components` | Map of Component/Value | Yes      | -         | JSON object mapping each scoring component to proposed value                    |
| `participant_message` | String                 | No       | null      | Optional message shared with the pilot                                          |
| `requester_id`        | UUIDv7                 | Yes      | -         | Identifier of the score reviewer                                                |
| `base_score_revision` | Integer                | Yes      | -         | Score revision number at time of request                                        |
| `request_time`        | Timestamp              | Yes      | -         | Time review request was submitted                                               |
| state                 | Enum                   | Yes      | Submitted | Current state: `Submitted`, `UnderReview`, `Approved`, `Rejected`, `Superseded` |
| `decision_actor`      | UUIDv7                 | No       | null      | Identifier of the entity that rendered decision                                 |
| `decision_time`       | Timestamp              | No       | null      | Time decision was made                                                          |
| `decision_message`    | String                 | No       | null      | Rationale for decision                                                          |

## Invariants and Constraints

- Cannot be submitted on scores marked Official or Locked
- `proposed_components` must be consistent with the score calculation rules for the flight
- `proposed_components` must not include `cumulative_penalty`; only the director applies it
- `decision_actor` and `decision_time` may be null while state is `Submitted`
- If state is `Approved`, the corresponding Score is updated to reflect the proposed values
- If an official edits or marks a score official while a review is pending, the review is superseded
- Superseded reviews are not processed and remain in `Superseded` state

## Lifecycle

```plaintext
Submitted -> UnderReview
UnderReview -> Approved (score updated)
UnderReview -> Rejected (message shared with pilot)
UnderReview -> Superseded (if official edits score or marks score official)
```

## Privacy and Scope

- `participant_message` is shared with the pilot
- `decision_message` rationale may be private to officials
- Review state and decisions are shared within the contest context
- Original score values are visible to all contest participants

## Audit and Synchronization

- Review request creation is audited as `ScoreReview`
- Review state transitions are audited
- `base_score_revision` enables optimistic locking on the Score record
- If score is superseded, all pending reviews are also superseded
- Mutation uses revision for optimistic locking
- Approved reviews trigger Score revision via separate audit entries
