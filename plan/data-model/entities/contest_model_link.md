# ContestModelLink

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md
**Purpose:** Contest-snapshot of the aircraft model used in a specific participation; historical scores reference this snapshot so later catalog edits do not retroactively rewrite history.
**Identifier:** `linkId` (UUIDv7)
**Parent entity:** ContestParticipation
**Child entities:** None

## Relationships
- Join between ModelCatalog and ContestParticipation
- Referenced by ContestParticipation via contestModelLinkRef
- Historical score records point to this snapshot

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| linkId | UUIDv7 | Yes | — | Primary key |
| contestId | UUIDv7 | Yes | — | Foreign key to Contest |
| linkId_part | UUIDv7 | Yes | — | Foreign key to ContestParticipation |
| catalogId | UUIDv7 | No | — | Foreign key to ModelCatalog (optional) |
| modelName | String | Yes | — | Model name for this contest entry |
| manufacturer | String | No | — | Model manufacturer for this contest entry |
| modelId | String | Yes | — | External model identifier |
| contestSpecificIdentifier | String | No | — | Contest-specific identifier for the model |
| revision | Integer | Yes | 0 | Revision counter for optimistic locking |

## Invariants and Constraints
- One ContestModelLink per ContestParticipation
- If catalogId is provided, the snapshot should match catalog definition (but not identical copy)
- Historical scores must reference ContestModelLink, not ModelCatalog directly
- Once flights are scored, the snapshot should not be modified to ensure historical record accuracy

## Lifecycle
- Created at contest registration when flight records are first needed
- Snapshot captures model info that must remain stable during contest
- After contest end, the snapshot remains as part of historical records

## Privacy and Scope
- Model information is public within the contest
- The link provides a stable reference for historical scores tied to the participation

## Audit and Synchronization
- Mutation through revision-based optimistic concurrency
- The snapshot is intended to remain stable once flights are recorded
- Historical integrity depends on immutable snapshots