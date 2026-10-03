# LandingTable

**Relationship to architecture-requirements:** [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** A lookup table that turns what a scorer selects for a landing into the points awarded. A table is not tied to a discipline: any table can be used with any discipline. Each discipline profile names the table it ships with as its default, directors can create their own tables, and the contest configuration selects the one a contest uses. A table is immutable: to change it, create a new table. Rows identify the table (name and unit of the key); the selectable entries are stored as LandingResult rows.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (top-level)  
**Child entities:** [LandingResult](landing_result.md) (many)

## Relationships

- Optionally owned by an Account (`owner_account_id`); a table shipped by the system has no owner
- Named as the default landing table by DisciplineProfiles (`DisciplineProfile.default_landing_table_id`). One table can be the default for several profiles and profile versions
- Selected by a ContestConfigurationRevision (`landing_table_id`)
- Contains LandingResults. Scores reference a LandingResult, which identifies the table

## Fields/Properties

| Field              | Type                       | Required | Default | Description                                                                              |
| ------------------ | -------------------------- | -------- | ------- | ---------------------------------------------------------------------------------------- |
| `id`               | PK                         | Yes      | -       | Stable identifier for the table                                                          |
| `owner_account_id` | UUIDv7                     | No       | null    | FK Account of the director who created the table. Null for a table shipped by the system |
| `name`             | string                     | Yes      | -       | Human-readable name, for example "F5J Standard Landing Table"                            |
| `input_unit`       | enum(meters, feet, points) | Yes      | -       | What the entry keys mean: a distance from the landing marker, or the points themselves   |
| `created_at`       | timestamptz                | Yes      | now     | When the table was created                                                               |

## Invariants and Constraints

- A table and all of its results are created together and never modified afterwards. A change means a new table. There is no revision number
- A table must have at least one result
- A table that a profile, a configuration revision, or a score refers to cannot be removed
- Any table visible to a director may be selected for any discipline. Only the unit of the keys, shown to the user, tells a scorer whether it suits their contest
- The profile's default is only the suggestion. When a director selects a different table in the contest configuration, that choice becomes their preference for that discipline, and later contests of that discipline preselect it instead of the system default. User preferences are a stretch goal, managed entirely by the client, and are not part of this data model. Until they exist, a new contest preselects the system default

## Lifecycle

- A system table is created by a system administrator, typically together with the profile that names it as its default, and is immutable
- A director creates their own table. It is complete when created
- Tables are retained for as long as anything refers to them. A director may remove their own table only while nothing refers to it
- A new profile version may keep naming the same default table, because tables never change

## Privacy and Scope

- System tables are readable by all clients and changed only by system administrators
- A director's tables are visible only to that director, as in `managing-system.md`. An installation that holds a contest using a table must have the table and its results

## Audit and Synchronization

- System tables synchronize down to every client. A director's tables synchronize with that director's data
- Because tables never change, synchronization only ever adds rows
