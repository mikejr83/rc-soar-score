# RoundConfig

**Relationship to architecture-requirements:** [contest.md](../../architecture-requirements/data/contest.md)
**Purpose:** Stores contest-scoped round setup and execution configuration. Defines how heats are organized in each round of a contest.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Contest
**Child entities:** None

## Relationships

- Belongs to a Contest (contest_id FK)
- One RoundConfig per contest per mode (Preliminary/Final)

## Fields/Properties

| Field              | Type                     | Required | Default | Description                         |
| ------------------ | ------------------------ | -------- | ------- | ----------------------------------- |
| `id`               | PK                       | Yes      | —       | Stable identifier                   |
| `contest_id`       | FK                       | Yes      | —       | The contest this config belongs to  |
| `mode`             | enum(Preliminary, Final) | Yes      | —       | Which phase this config applies to  |
| `groups_per_round` | int                      | Yes      | —       | Number of heats per round           |
| `group_size`       | int                      | Yes      | —       | Maximum number of pilots per heat   |
| `lane_mode`        | enum(Shared, Separate)   | No       | Shared  | Whether pilots share run lanes      |
| `revision`         | int                      | Yes      | —       | Revision number for change tracking |

## Invariants and Constraints

- The combination (contest_id, mode, revision) must be unique.
- groups_per_round must be positive.
- group_size must be positive and at least 2.
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
