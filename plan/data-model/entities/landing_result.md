# LandingResult

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** One selectable entry in a LandingTable. The scorer picks an entry by its key and label, and the entry resolves to the points awarded. A score stores the selected entry's identifier, so the key, the points, and the table that produced them are always recoverable.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** [LandingTable](landing_table.md) (via `landing_table_id`)  
**Child entities:** None

## Relationships

- Belongs to one LandingTable (1:N)
- Referenced by score components (ScoreAttempt `raw_components` and OfficialScore `components`) as the selected landing

## Fields/Properties

| Field              | Type   | Required | Default | Description                                                                                                                                  |
| ------------------ | ------ | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | PK     | Yes      | -       | Stable identifier for this entry. This is the value stored in a score                                                                        |
| `landing_table_id` | FK     | Yes      | -       | FK LandingTable                                                                                                                              |
| `entry_key`        | string | Yes      | -       | What the scorer selects, for example `50` for a table keyed by points, or `within_1m` for a table keyed by distance. Unique within the table |
| `display_value`    | string | Yes      | -       | Label shown to the user, for example "Within 1 m"                                                                                            |
| `point_value`      | int    | Yes      | -       | Landing points awarded when this entry is selected. Never negative                                                                           |
| `ordinal_position` | int    | Yes      | -       | Position of the entry in the selection list                                                                                                  |

## Invariants and Constraints

- (`landing_table_id`, `entry_key`) is unique
- (`landing_table_id`, `ordinal_position`) is unique
- `point_value` is at least 0
- `display_value` is not empty
- Results are immutable and are created with their table
- The system takes the points from `point_value` of the selected entry, never from the label the user saw

## Lifecycle

Created together with its table and never modified or removed on its own. It is removed only if its whole table is removed.

## Privacy and Scope

Scope follows the LandingTable: system entries are readable by all clients, and a director's entries are visible only to that director.

## Audit and Synchronization

- A score stores only the entry's `id`. Because entries never change, the key, the points, and the table are reproducible from it
- Entries are replicated with their table and never updated
