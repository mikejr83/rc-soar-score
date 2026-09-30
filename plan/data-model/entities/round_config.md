# RoundConfig

**Relationship to architecture-requirements:** [contest.md](../../architecture-requirements/data/contest.md)
**Purpose:** Stores contest-scoped round setup and execution configuration. Defines how heats are organized in each round of a contest.
**Identifier:** `entity_id` (UUIDv7)
**Parent entity:** Contest
**Child entities:** None

## Relationships
- Belongs to a Contest (`contestId` FK)
- One RoundConfig per contest per mode (Preliminary/Final)

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `configId` | PK | Yes | — | Stable identifier |
| `contestId` | FK | Yes | — | The contest this config belongs to |
| `mode` | enum(Preliminary, Final) | Yes | — | Which phase this config applies to |
| `groupsPerRound` | int | Yes | — | Number of heats per round |
| `groupSize` | int | Yes | — | Maximum number of pilots per heat |
| `laneMode` | enum(Shared, Separate) | No | Shared | Whether pilots share run lanes |
| `revision` | int | Yes | — | Revision number for change tracking |

## Invariants and Constraints
- The combination (`contestId`, `mode`, `revision`) must be unique.
- `groupsPerRound` must be positive.
- `groupSize` must be positive and at least 2.
- A contest may have separate RoundConfig entries for Preliminary and Final modes.
- Changing group configuration creates a new revision.

## Lifecycle
```
Created -> Active -> (optionally) Replaced by new config revision
```

## Privacy and Scope
- Private to the owning contest.
- Visible to participants once scoring is open.

## Audit and Synchronization
- Any group configuration change creates a new revision record.
- Previous revisions remain for audit trail.