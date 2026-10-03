# ReFlight

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md  
**Purpose:** Records one re-flight: an extra chance to fly, given to one or more pilots for a round. It holds the method used, the group it flies in, the reason, the status from proposal to finalization, and the draw inputs needed to reproduce a random draw. The pilots involved are in ReFlightParticipant, and the flights themselves are MatrixAssignment rows of type `Reflight`. A re-flight never overwrites the original flight.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Contest  
**Child entities:** [ReFlightParticipant](re_flight_participant.md)

## Relationships

- Belongs to a Contest (`contest_id`)
- Credited to a Round (`credited_round_id`), the round whose result it affects
- Arises from a source group (`source_round_id`, `source_group`), the group in which the awarding flight was flown
- Flies in a Round and group (`scheduled_round_id`, `flown_group`)
- May follow an earlier ReFlight (`previous_reflight_id`) when a re-flight is itself awarded a re-flight
- Decided under a ContestConfigurationRevision (`config_revision_id`)
- Referenced by the MatrixAssignment rows it creates (`re_flight_id`)
- Has ReFlightParticipant rows

## Fields/Properties

| Field                      | Type        | Required    | Default  | Description                                                                                                                                                            |
| -------------------------- | ----------- | ----------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7      | Yes         | -        | Primary key                                                                                                                                                            |
| `contest_id`               | UUIDv7      | Yes         | -        | FK Contest                                                                                                                                                             |
| `credited_round_id`        | UUIDv7      | Yes         | -        | FK Round whose score is affected                                                                                                                                       |
| `source_round_id`          | UUIDv7      | Yes         | -        | FK Round in which the awarding flight was flown                                                                                                                        |
| `source_group`             | int         | Yes         | -        | Group number of the awarding flight within the source round                                                                                                            |
| `type`                     | enum        | Yes         | -        | `MoveToGroup`, `RandomDraw`, or `ReflyEntireGroup`                                                                                                                     |
| `sequence`                 | int         | Yes         | 1        | The re-flight number for the source group: 1 for the first re-flight of that group, then incrementing                                                                  |
| `previous_reflight_id`     | UUIDv7      | No          | -        | FK ReFlight this one follows, when a re-flight is awarded a re-flight                                                                                                  |
| `status`                   | enum        | Yes         | Proposed | `Proposed`, `DrawPending`, `AwaitingResponses`, `ReadyToFly`, `Finalized`, or `Cancelled`                                                                              |
| `reason`                   | string      | Yes         | -        | The director's explanation for awarding the re-flight                                                                                                                  |
| `scheduled_round_id`       | UUIDv7      | Yes         | -        | FK Round the re-flight is flown in                                                                                                                                     |
| `flown_group`              | int         | Yes         | -        | Group number the re-flight is flown in. An existing group for `MoveToGroup`; a group numbered after the round's regular groups for `RandomDraw` and `ReflyEntireGroup` |
| `deviation_acknowledged`   | bool        | Yes         | false    | True when the director chose a method other than the discipline's preferred one while the preferred one was achievable, and acknowledged the deviation                 |
| `requested_group_size`     | int         | No          | -        | `RandomDraw` only. The group size the director asked for                                                                                                               |
| `achievable_max_size`      | int         | No          | -        | `RandomDraw` only. The largest group the contest configuration allows                                                                                                  |
| `size_exception_confirmed` | bool        | Yes         | false    | True when the requested size could not be met and the director confirmed the exception                                                                                 |
| `random_seed`              | bigint      | No          | -        | `RandomDraw` only. Seed that makes the draw reproducible                                                                                                               |
| `algorithm_version`        | string      | No          | -        | `RandomDraw` only. Version of the draw routine                                                                                                                         |
| `config_revision_id`       | UUIDv7      | Yes         | -        | FK ContestConfigurationRevision the re-flight was decided under                                                                                                        |
| `created_by`               | UUIDv7      | Yes         | -        | FK Account of the director who created it                                                                                                                              |
| `created_at`               | timestamptz | Yes         | -        | When it was created                                                                                                                                                    |
| `group_finalized_by`       | UUIDv7      | Conditional | -        | FK Account that finalized the group. Set when status becomes `ReadyToFly`                                                                                              |
| `group_finalized_at`       | timestamptz | Conditional | -        | When the group was finalized                                                                                                                                           |
| `finalized_by`             | UUIDv7      | Conditional | -        | FK Account that finalized the outcome. Set when status becomes `Finalized`                                                                                             |
| `finalized_at`             | timestamptz | Conditional | -        | When the outcome was finalized                                                                                                                                         |
| `cancelled_by`             | UUIDv7      | Conditional | -        | FK Account that cancelled it. Set when status becomes `Cancelled`                                                                                                      |
| `cancelled_at`             | timestamptz | Conditional | -        | When it was cancelled                                                                                                                                                  |
| `cancel_reason`            | string      | Conditional | -        | Why it was cancelled                                                                                                                                                   |
| `revision`                 | int         | Yes         | 0        | Row-level counter for optimistic locking                                                                                                                               |

## Invariants and Constraints

- (`source_round_id`, `source_group`, `sequence`) is unique. A re-flight of a re-flight links to the preceding one and receives the next number; it never replaces it
- A re-flight never overwrites the original attempt. The original flight, the re-flight, the selected official result, and any superseded result stay distinguishable
- A re-flight can be created only while the awarded pilots' scores are not locked and the contest is not `Completed`, unless an authorized score-correction workflow permits it
- **Awarded pilots:** at least one participant has the role `Awarded`
- **`MoveToGroup`:** the target is an existing group of the scheduled round that has an open spot, and the move must preserve team protection. It involves only the awarded pilots and has no draw fields
- **`RandomDraw`:**
  - The group is made up of the awarded pilots plus pilots drawn at random from the eligible pool.
  - The discipline profile defines the pool, the exclusions, the minimum and default group size, and the team constraints. Same-team pilots, retired pilots, and the awarded pilots themselves are excluded.
  - The draw is reproducible from `random_seed`, `algorithm_version`, the candidate list, and the order drawn.
  - If the requested size cannot be achieved, the achievable maximum is shown and the director must confirm the exception.
  - A drawn pilot may decline. The draw repeats until the group is filled. If it cannot be filled, this re-flight is cancelled and the director moves on to the next method.
  - A draw is not final until the director finalizes the group.
- **`ReflyEntireGroup`:** the whole source group flies again as a copy that retains its original membership and scores as history. There is no opt-out and no draw
- `flown_group` for a regular group is at most the scheduled round's `group_count`. A re-flight group is numbered after the regular groups, and a re-flight group is never available to a late addition
- The discipline profile defines the group size, the normalization population, and how the result is selected. The selection rule reads each pilot's role in the re-flight. These are not generic contest fields
- **Statuses:** `Flown` and `Scored` are not stored. They follow from the score state of the re-flight's flights
  - `MoveToGroup` and `ReflyEntireGroup` go from `Proposed` straight to `ReadyToFly`
  - `RandomDraw` goes `Proposed`, `DrawPending`, `AwaitingResponses`, `ReadyToFly`
  - `ReadyToFly` is the group being finalized and its assignments created
  - `Finalized` closes the outcome. A finalized re-flight is immutable
  - A re-flight can be cancelled at any point before `Finalized`. Cancellation never removes historical scores or responses. After flights have been scored it requires an authorized correction
- Offers, responses, and notifications are optional in the first release. They are modelled here so they can be added without changing the structure

## Lifecycle

```plaintext
Proposed -> ReadyToFly -> Finalized                                  (MoveToGroup, ReflyEntireGroup)
Proposed -> DrawPending -> AwaitingResponses -> ReadyToFly -> Finalized     (RandomDraw)
any status before Finalized -> Cancelled
```

## Privacy and Scope

- Participants' responses, the candidate pool, and the draw internals are private to contest administration
- The resulting re-flight groups and their scores are part of the schedule and results once the re-flight is `ReadyToFly`

## Audit and Synchronization

- Creating, finalizing the group, finalizing the outcome, and cancelling are each audited with actor, authority, and reason
- Every response, decline, and director override is recorded on ReFlightParticipant and audited
- Offline operation never blocks creating, scoring, or finalizing a re-flight. Pending notifications are delivered when connectivity returns
- All changes that create the re-flight's assignments and placeholders happen in one transaction
