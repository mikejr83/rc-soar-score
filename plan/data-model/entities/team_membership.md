# TeamMembership

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** Joins participation links to teams, enabling score aggregation by team. Whether the member flies or not comes from the participation's role.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Team  
**Child entities:** None

## Relationships

- Belongs to Team via team_id foreign key
- Belongs to ContestParticipation via contest_participation_id foreign key
- Pilot membership is fixed for the duration of the matrix revision
- Non-flier membership (helpers, team managers) may change during the contest without redrawing the flight matrix
- Controls which pilots a helper may score for

## Fields/Properties

| Field                      | Type    | Required | Default | Description                                                                                                   |
| -------------------------- | ------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------- |
| `id`                       | UUIDv7  | Yes      | —       | Primary key                                                                                                   |
| `team_id`                  | UUIDv7  | Yes      | —       | Foreign key to Team                                                                                           |
| `contest_participation_id` | UUIDv7  | Yes      | —       | Foreign key to ContestParticipation                                                                           |
| `contest_id`               | UUIDv7  | Yes      | —       | Foreign key to Contest (denormalized for sync scoping; must match the team's and the participation's contest) |
| `revision`                 | Integer | Yes      | 0       | Revision counter for optimistic locking                                                                       |

## Invariants and Constraints

- A participation link can belong to only one team at a time
- Pilot membership cannot change during the contest (fixed per matrix revision)
- Non-flier membership may change during the contest without redrawing
- The combination of team_id and contest_participation_id must be unique

## Lifecycle

- Created when a participation is linked to a team
- Updated when team composition changes (non-fliers) or when pilot status changes
- Deleted when a link is removed from the team

## Privacy and Scope

- Team membership is visible to all participants in the contest
- The member's role, taken from the participation, is visible to all participants

## Audit and Synchronization

- Mutation through revision-based optimistic concurrency
- Adding or removing non-flier members does not retroactively change existing scores
