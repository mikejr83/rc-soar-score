# ContestParticipation

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md
**Purpose:** Authoritative contest-specific snapshot that links a participant profile to a contest with contest-specific class, role, number, team, and model information.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Contest
**Child entities:** MatrixAssignment, ScorePlaceholder, Invitation, ContestModelLink

## Relationships

- Links ParticipantProfile to Contest
- Parent of MatrixAssignment (flight assignments)
- Parent of ScorePlaceholder (score records)
- Parent of Invitation (contest invitation)
- Parent of ContestModelLink (model used in contest)

## Fields/Properties

| Field                    | Type    | Required | Default | Description                                              |
| ------------------------ | ------- | -------- | ------- | -------------------------------------------------------- |
| `id`                     | UUIDv7  | Yes      | —       | Primary key                                              |
| `contest_id`             | UUIDv7  | Yes      | —       | Foreign key to Contest                                   |
| `participant_profile_id` | UUIDv7  | Yes      | —       | Foreign key to ParticipantProfile                        |
| `cls`                    | String  | Yes      | —       | Class designation for this contest                       |
| `role_id`                | UUIDv7  | Yes      | —       | Foreign key to Role definition                           |
| `role_type`              | Enum    | Yes      | Pilot   | Role type: Pilot or NonFlier                             |
| `participant_number`     | Integer | No       | —       | Participant number (allocated at first draw)             |
| `team_membership_id`     | UUIDv7  | No       | —       | Reference to TeamMembership if on a team                 |
| `scoring_uuid`           | UUIDv7  | Yes      | —       | Contest-scoped public identifier for scoring             |
| `contest_model_link_id`  | UUIDv7  | No       | —       | Reference to ContestModelLink                            |
| `privacy_overrides`      | Object  | No       | {}      | Contest-specific privacy settings                        |
| `participation_status`   | Enum    | Yes      | Pending | Status (Pending, Accepted, Active, Completed, Withdrawn) |
| `revision`               | Integer | Yes      | 0       | Revision counter for optimistic locking                  |

## Invariants and Constraints

- A profile can participate in multiple contests but only once per contest
- Participant number is allocated at first applicable entry draw and not renumbered during contest
- scoring_uuid must be unique within the contest scope
- cls must reference a valid class defined for the contest
- role_id must reference a valid role in the contest
- If team_membership_id is set, it must reference an active TeamMembership
- participation_status state transitions: Pending→Accepted→Active→Completed or Withdrawn at any stage after Accepted

## Lifecycle

```
Pending → Accepted → Active → Completed
           ↓
        Withdrawn
```

- Created when director issues invitation or participant joins waiting list
- Moves to Accepted when participant confirms
- Moves to Active when contest operations begin
- Moves to Completed when contest is finalized
- Can move to Withdrawn from any post-Accepted state

## Privacy and Scope

- Contest-scoped data: only participants in this contest see contest-specific details
- scoring_uuid is the public identifier used in results and standings
- privacy_overrides can restrict visibility of specific fields (e.g., hide contact info from other participants even if shared profile)
- Team membership is public within contest

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Participant number allocation is idempotent once assigned
- Contest-specific overrides do not affect global profile data
- All participant-specific data (assignments, scores, model) must be cleaned up or archived before participation can be terminated
