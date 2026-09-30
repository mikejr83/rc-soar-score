# LandingTable

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Stores a versioned lookup table mapping a selected key (e.g. distance) to resolved scoring values (e.g. points). Used in disciplines with landing distance scoring.
**Identifier:** `entity_id` (UUIDv7)
**Parent entity:** None
**Child entities:** None

## Relationships
- Score records reference the table revision used, retaining historical reproducibility.

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `tableId` | PK | Yes | — | Stable identifier for the table |
| `name` | string | Yes | — | Human-readable name |
| `revision` | int | Yes | — | Revision number (increments monotonically) |
| `inputUnit` | enum(meters, feet) | Yes | — | Unit of measurement for the input key |
| `inputMeaning` | enum(distance, altitude, duration) | Yes | — | Semantic meaning of the input |
| `entries` | map<int, int> | Yes | {} | Mapping of input key to resolved points |

## Invariants and Constraints
- The combination (`tableId`, `revision`) must be unique.
- `revision` starts at 1 and increments monotonically per `tableId`.
- Entries must be ordered in ascending order by input key.
- Each entry's input key must be unique (no duplicate distances).
- Entries may contain explicit zero points for specific ranges.
- Table may implement different behavior below vs above specific thresholds.
- Resolved points must be non-negative integers.
- Once published, entries and metadata are immutable for that revision.

## Lifecycle
```
Drafted -> Published -> Superseded (by new revision)
```
- New revisions may be created at any time.
- Published revisions remain queryable for historical score reproduction.
- Superseded revisions are not deleted; they persist for reproducibility.

## Privacy and Scope
- Shared reference table across contests.
- Readable by all clients; mutations by table administrators only.

## Audit and Synchronization
- A score stores the selected key, resolved points, and table revision used.
- Historical scores remain reproducible if the table is updated with new revisions.
- New revisions are created to modify a table (never overwrite old revisions).