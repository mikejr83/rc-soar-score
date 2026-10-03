# ReFlightParticipant

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md  
**Purpose:** Records a pilot's part in one re-flight: whether they were awarded it, drawn for it, are re-flying with the group, were only a candidate, or were excluded. It also holds their response to an offer and the state of the notification sent to them. It replaces the lists of pilots and the response and notification arrays that used to sit on the re-flight.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** [ReFlight](re_flight.md)  
**Child entities:** None

## Relationships

- Belongs to a ReFlight (`re_flight_id`) and a Contest (`contest_id`, denormalized)
- References the pilot's ContestParticipation (`contest_participation_id`)
- Optionally references the MatrixAssignment created for the pilot (`assignment_id`)

## Fields/Properties

| Field                      | Type        | Required | Default     | Description                                                                                                                                                                      |
| -------------------------- | ----------- | -------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7      | Yes      | -           | Primary key                                                                                                                                                                      |
| `contest_id`               | UUIDv7      | Yes      | -           | FK Contest (denormalized)                                                                                                                                                        |
| `re_flight_id`             | UUIDv7      | Yes      | -           | FK ReFlight                                                                                                                                                                      |
| `contest_participation_id` | UUIDv7      | Yes      | -           | FK ContestParticipation. A pilot                                                                                                                                                 |
| `role`                     | enum        | Yes      | -           | `Awarded` (entitled to the re-flight), `Drawn` (selected from the pool), `GroupMember` (re-flying with a re-flown group), `Candidate` (in the pool, not selected), or `Excluded` |
| `excluded_reason`          | enum        | No       | -           | Set when `role` is `Excluded`: `SameTeam`, `Retired`, `NotEligible`, `DirectorExcluded`, or `Declined`                                                                           |
| `draw_position`            | int         | No       | -           | Order in which a pilot was drawn, starting at 1. Together with the seed it reproduces the draw                                                                                   |
| `response`                 | enum        | Yes      | NotRequired | `NotRequired` (awarded, group member, or moved pilots), `Pending`, `Accepted`, or `Declined`                                                                                     |
| `responded_by`             | enum        | No       | -           | `Participant` or `Director`. A director can record a decline or acceptance manually                                                                                              |
| `responded_at`             | timestamptz | No       | -           | When the response was recorded                                                                                                                                                   |
| `notification_state`       | enum        | Yes      | NotRequired | `NotRequired`, `Pending` (queued, for example while offline), `Delivered`, or `Failed`                                                                                           |
| `notified_at`              | timestamptz | No       | -           | When the notification was delivered                                                                                                                                              |
| `acknowledged_at`          | timestamptz | No       | -           | When the pilot acknowledged it                                                                                                                                                   |
| `assignment_id`            | UUIDv7      | No       | -           | FK MatrixAssignment (type `Reflight`) created for this pilot when the group was finalized                                                                                        |
| `revision`                 | int         | Yes      | 0           | Row-level counter for optimistic locking                                                                                                                                         |

## Invariants and Constraints

- (`re_flight_id`, `contest_participation_id`) is unique
- The pilot must have the Pilot role
- A drawn pilot who declines becomes `Excluded` with reason `Declined`, and the declined row stays in the history
- A declined or excluded pilot is not in the finalized group
- Only pilots who are eligible under the discipline and the contest configuration can be drawn. Notifications are advisory and do not decide eligibility. The director can finalize while offline or without an acknowledgement
- A `GroupMember` has `response` `NotRequired`, because re-flying a whole group has no opt-out
- `assignment_id` is set for every pilot who flies and is null for candidates and excluded pilots
- The discipline's selection rule reads `role`. An `Awarded` pilot's re-flight result is their score, and for other pilots in the group the better of their two results becomes the round score, as the discipline defines it. Raw scores are always retained

## Lifecycle

Created when the re-flight is proposed (awarded pilots) or when the pool and draw are made. `response` and `notification_state` change as offers go out and are answered. The row is never deleted.

## Privacy and Scope

- Responses, the candidate pool, and exclusions are private to contest administration. A pilot sees only their own offer and its outcome
- Participant-facing results show which flight supplied the official result and identify any pending or cancelled re-flight

## Audit and Synchronization

- Every response, decline, manual director override, and notification outcome is recorded and audited
- Offers, responses, and notifications are optional in the first release; the columns default to `NotRequired`
- Pending notifications are delivered when connectivity returns
