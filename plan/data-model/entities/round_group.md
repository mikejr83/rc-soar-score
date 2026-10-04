# RoundGroup

**Relationship to architecture-requirements:** plan/architecture-requirements/data/matrix-and-assignments.md, plan/architecture-requirements/data/scores-and-results.md  
**Purpose:** One group within a round: the set of pilots who fly together. It exists so a group can be locked. A lock on a group stops participant changes and later corrections to every score flown in it until the director unlocks it. A group holds no other data, because its members come from the assignments that reference it and its size is derived.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Round  
**Child entities:** None (MatrixAssignment rows reference a group by round and group number)

## Relationships

- Belongs to a Round (`round_id`) and to a Contest (`contest_id`, denormalized for sync scoping)
- Referenced by MatrixAssignment through (`scheduled_round_id`, `group`), the group in which the flight is flown
- Locked by an Account (`locked_by`), the director or a local operator under the director's authority

## Fields/Properties

| Field          | Type        | Required | Default | Description                                               |
| -------------- | ----------- | -------- | ------- | --------------------------------------------------------- |
| `id`           | UUIDv7      | Yes      | -       | Stable identity                                           |
| `contest_id`   | UUIDv7      | Yes      | -       | FK Contest (denormalized; must match the round's contest) |
| `round_id`     | UUIDv7      | Yes      | -       | FK Round the group belongs to                             |
| `group_number` | int         | Yes      | -       | Group number within the round, starting at 1              |
| `status`       | enum        | Yes      | Open    | `Open` or `Locked`                                        |
| `locked_by`    | UUIDv7      | No       | -       | FK Account that locked the group. Null while `Open`       |
| `locked_at`    | timestamptz | No       | -       | When the group was locked. Null while `Open`              |
| `revision`     | int         | Yes      | 0       | Row-level sync counter, incremented when `status` changes |

## Invariants and Constraints

- (`round_id`, `group_number`) is unique
- A round has one RoundGroup for each of its regular groups, numbered 1 to the round's `group_count`, created with the round. A re-flight group, numbered after the regular groups, gets its RoundGroup when the re-flight's group is finalized
- A group's size is derived from its current assignments and is never stored
- `locked_by` and `locked_at` are set exactly when `status` is `Locked`, and cleared when the group is unlocked
- While a group is `Locked`, participant changes to the scores flown in it are rejected, and so are later corrections, unless the contest director overrides with a recorded reason. Review requests cannot be submitted on those scores
- Locking a group does not complete, pause, or archive anything and does not change the contest's execution lifecycle
- A lock is evaluated together with the others: a score is locked if its own lock, its group, its round, or the contest is locked (`Contest.Locked > Round.Locked > Group.Locked > Score.Locked`)
- A RoundGroup is never deleted. When its round is superseded or cancelled it stops being current with the round

## Lifecycle

```plaintext
Open <-> Locked
```

The director locks a group, typically once its scores are official, and may unlock it. Each change is audited with the actor and a reason.

## Privacy and Scope

- The group structure is part of the published flight schedule once the matrix revision is finalized. The lock state is internal to contest administration, although participants see the effect on their scores

## Audit and Synchronization

- Contest data, synchronized through the contest stream
- Each lock and unlock is an audited state change that increments `revision`, with the actor, base revision, and reason
- Creation happens in the transaction that creates the round, or that finalizes a re-flight group
