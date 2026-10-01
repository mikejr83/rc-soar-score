# LandingTable

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)
**Purpose:** Stores the identity of a versioned lookup table used for scoring lookups. Rows in this table identify the table (name, unit, meaning); the score values themselves are stored in separate LandingResult rows.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None
**Child entities:** LandingResult (many)

## Relationships

- Score records reference the table revision used, retaining historical reproducibility.

## Fields/Properties

| Field        | Type               | Required | Default | Description                                |
| ------------ | ------------------ | -------- | ------- | ------------------------------------------ |
| `id`         | PK                 | Yes      | —       | Stable identifier for the table            |
| `name`       | string             | Yes      | —       | Human-readable name                        |
| `revision`   | int                | Yes      | —       | Revision number (increments monotonically) |
| `input_unit` | enum(meters, feet) | Yes      | —       | Unit of measurement for the input key      |

## Invariants and Constraints

- (id, revision) must be unique.
- revision starts at 1 and increments monotonically per id.
- Once published, row data (name, unit, meaning) is immutable for that revision.

## Lifecycle

```
Drafted -> Published -> Superseded (by new revision)
```

- New revisions may be created at any time.
- Published revisions remain queryable for historical score reproduction.
- Superseded revisions are not deleted; they persist for reproducibility.
- Row edits require a new revision (never modify a published row).

## Privacy and Scope

- Shared reference table across contests.
- Readable by all clients; mutations by table administrators only.

## Synchronization

- New revisions add rows (never modify existing rows).
- Revision numbers must be unique per id.
