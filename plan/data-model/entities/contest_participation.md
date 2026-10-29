# ContestParticipation

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md  
**Purpose:** Authoritative contest-specific snapshot that links a participant profile to a contest with contest-specific class, role, number, team, and model information. Every person involved in a contest has one: pilots, helpers, team managers, and officials alike. Only participations with the Pilot role fly and receive scores.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Contest  
**Child entities:** MatrixAssignment, ScorePlaceholder, Invitation, ContestModelLink, ContestRoundModel

## Relationships

- Links ParticipantProfile to Contest
- References a Role (`role_id`) that says whether the participant is a pilot or a non-flier
- Referenced by TeamMembership when the participant is on a team. A participant with no team, such as an official, has none
- Parent of MatrixAssignment (flight assignments)
- Parent of ScorePlaceholder (score records)
- Parent of Invitation (contest invitation)
- Parent of ContestModelLink (the models the pilot entered in the contest: none, one, or several; non-fliers have none) and, for disciplines that need it, ContestRoundModel

## Fields/Properties

| Field                    | Type    | Required | Default               | Description                                                                                                                                                                                                                                                                                                                               |
| ------------------------ | ------- | -------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                     | UUIDv7  | Yes      | —                     | Primary key                                                                                                                                                                                                                                                                                                                               |
| `contest_id`             | UUIDv7  | Yes      | —                     | Foreign key to Contest                                                                                                                                                                                                                                                                                                                    |
| `participant_profile_id` | UUIDv7  | Yes      | —                     | Foreign key to ParticipantProfile                                                                                                                                                                                                                                                                                                         |
| `classification`         | String  | No       | —                     | Optional free-text label for a pilot's class in this contest, for example "Expert", "Senior", "Junior". Only used when the contest has classes enabled, only for pilots, and for reporting only. There is no list of classes                                                                                                              |
| `role_id`                | UUIDv7  | Yes      | System Pilot role     | Foreign key to Role. The role assigned to this participant for the contest                                                                                                                                                                                                                                                                |
| `role_name`              | String  | Yes      | Role display name     | Snapshot of the role's display name taken when the role is assigned. It never follows later renames of the role, so past contests keep the name they were run with                                                                                                                                                                        |
| `role_type`              | Enum    | Yes      | Pilot                 | `Pilot` or `NonFlier`. The authoritative statement of whether this participant is a pilot who flies and receives scores, or a non-flier such as a helper or official who does not. It is a snapshot of the role's type and is never inferred from the role's name. The draw, assignments, scoring, and permissions all key off this value |
| `participant_number`     | Integer | No       | —                     | The participant's number in the contest, one running sequence shared by all roles. Null until allocated at the first draw                                                                                                                                                                                                                 |
| `scoring_uuid`           | UUIDv4  | Yes      | Generated on creation | Contest-scoped public identifier for scoring and the access identifier in an invitation link. A random UUIDv4, not a v7, because it must not be sequential or guessable. It carries no account id or email                                                                                                                                |
| `retired_at_round`       | Integer | No       | null                  | Pilots only. Null means the pilot has not retired. Otherwise the pilot is retired from this round: rounds from here on that have no accepted score are evaluated as retired zeros without creating score records. Free-text retirement reasons are not tracked                                                                            |
| `revision`               | Integer | Yes      | 0                     | Revision counter for optimistic locking                                                                                                                                                                                                                                                                                                   |

## Invariants and Constraints

- A profile can participate in multiple contests but only once per contest
- `classification` is only set for pilots, and only when the contest has classes enabled
- The participant number comes from a single running sequence per contest that is shared by every role type, so no two participants share a number: (`contest_id`, `participant_number`) is unique. Numbers are allocated at the first draw and never renumbered. A participant added afterwards receives the next number when they are added. A single administration installation allocates them, so offline creation cannot collide
- scoring_uuid must be unique within the contest scope: (`contest_id`, `scoring_uuid`) is unique
- (`contest_id`, `participant_profile_id`) is unique, so a profile appears once per contest
- `role_id` must reference a system role or a role owned by the contest's director, and must not be archived when it is assigned
- `role_type` equals the type of the referenced role at the time it was assigned
- `role_name` and `role_type` are snapshots. Renaming, retyping, or archiving the role never changes them
- Only participations with `role_type` `Pilot` have assignments, score placeholders, and scores
- `role_type` cannot be changed from `Pilot` once the participation has a score. A pilot with assignments but no scores can change: the assignments and their empty score placeholders are deleted (see MatrixAssignment) and the draw needs redoing. A participation changed to `Pilot` after a draw is a late add and follows the matrix rules. Every change to `role_type` is an audited mutation
- Team membership is held by TeamMembership, which references this participation. A participation belongs to at most one team in a contest
- `retired_at_round` is set only on a participation with `role_type` `Pilot`, and is at least 1
- Retirement is an overlay, not a status: it creates no records, and accepted scores in earlier rounds are untouched. From `retired_at_round` on, new score submissions and review requests are rejected and read access remains
- Only pilots with no `retired_at_round` are included in a new draw. Existing assignments of a retired pilot remain as history
- The invitation and its delivery are tracked on Invitation, not here. There is no participation status

## Lifecycle

- Created when the director adds the participant to the contest, as a pilot or a non-flier
- A pilot can be added at any time before the contest is `Completed`. Once a matrix exists, the pilot is added only if the remaining rounds have group space for them, and the add creates `LateAdd` assignments. Before any score exists they are placed at random in the existing groups and the director is advised to redraw. After scores exist the director chooses open groups, and rounds the pilot never gets a make-up for count as not entered. If no group has space, the pilot is not added and the director is told; redrawing the later rounds is the director's decision
- A pilot retires from a round, either through their own scoring link or by the director, which sets `retired_at_round`. The change is an audited mutation, recorded with its actor and time. A director may reverse it by clearing the value, also audited
- A participation with no scores can be deleted, which creates a tombstone. If it has assignments, they and their empty score placeholders are deleted with it and the draw needs redoing. One with scores can only be retired
- Non-fliers are never retired. They are removed by deleting the participation, and their invitations are revoked

## Privacy and Scope

- The participation holds no copy of the participant's name or other identity details. They are read from the linked ParticipantProfile, so a profile edit shows in the contest. Published results take their own copy, in PublicationParticipant, at publish time
- There are no per-participation privacy overrides yet. A participant's details leave the private contest only through the publication, where they can be redacted (see PublicationParticipant). Typed override fields can be added when a requirement needs them
- Contest-scoped data: only participants in this contest see contest-specific details
- scoring_uuid is the public identifier used in results and standings
- Team membership is public within contest

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Participant number allocation is idempotent once assigned
- A participation that has scores (or re-flights) cannot be deleted; the pilot retires instead
