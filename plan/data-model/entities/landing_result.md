# LandingResult

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Stores individual scoring rows for a LandingTable. Each row maps an entered value (e.g., distance in meters) to its resolved point value. Used by disciplines with landing distance/point scoring.
**Identifier:** `id` (UUIDv7)
**Parent entity:** LandingTable (via landing_table_id FK)
**Child entities:** None

## Relationships

- One LandingTable has many LandingResults (1:N)

## Fields/Properties

| Field              | Type   | Required | Default | Description                                                      |
| ------------------ | ------ | -------- | ------- | ---------------------------------------------------------------- |
| `id`               | PK     | Yes      | —       | Stable identifier for this row                                   |
| `landing_table_id` | FK     | Yes      | —       | References LandingTable.id                                       |
| `point_value`      | int    | Yes      | —       | The entered value (e.g., distance in meters)                     |
| `display_value`    | string | Yes      | —       | Human-readable display (e.g., "4.0 m", "10 pts")                 |
| `ordinal_position` | int    | Yes      | —       | The position where this value is displayed in the selection list |

## Invariants and Constraints

- (landing_table_id, point_value) must be unique — no duplicate point values
- point_value must be ≥ 0
- display_value must not be empty

## Lifecycle

```plaintext
Drafted -> Published
```

- Rows are added to a LandingTable before the contest configuration revision is published
- Published rows cannot be edited; only added or (via tombstone) removed
- New contest configuration revisions can cite the same table with more rows

## Privacy and Scope

- Scope derived from LandingTable (shared reference table)
- Readable by all clients; mutations by table administrators only

## Audit and Synchronization

- Score records store point_value and landing_table_id for full reproducibility
- Table row additions/edits do NOT invalidate existing scores — each row is immutable once published
- Synchronization follows standard entity sync: new rows are replicated, tombstones indicate deleted rows
