# Team

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md
**Purpose:** Represents a team within a contest for which pilot totals are aggregated to produce team rankings.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Contest
**Child entities:** TeamMembership

## Relationships
- Belongs to Contest via contest_id foreign key
- Parent of TeamMembership via team_id foreign key
- Team totals are derived from eligible pilot contest totals, never entered as source data

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | UUIDv7 | Yes | — | Primary key |
| contest_id | UUIDv7 | Yes | — | Foreign key to Contest |
| name | String | Yes | — | Team name (unique within contest) |
| pilot_totals | Integer | No | — | Number of pilot totals used for team result |
| revision | Integer | Yes | 0 | Revision counter for optimistic locking |

## Invariants and Constraints
- Team name must be unique within a contest
- A team can only have one membership per participation link
- pilot_totals must be within [1, team size] range
- A pilot can only be on one team per contest

## Lifecycle
- Created when director creates teams or at contest setup
- Persisted throughout the contest
- Team results are derived and computed from pilot flight records

## Privacy and Scope
- Team name and composition are visible to all participants in the contest
- Team-specific results are part of contest public results

## Audit and Synchronization
- Mutation through revision-based optimistic concurrency
- Adding or removing members does not retroactively change existing scores