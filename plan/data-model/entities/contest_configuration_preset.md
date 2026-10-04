# ContestConfigurationPreset

**Relationship to architecture-requirements:** [contest.md](../../architecture-requirements/data/contest.md), [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** A director's saved, named set of contest settings that they can start a new contest from. A preset holds the same full resolved settings as a configuration revision, for one discipline, so a director who runs similar contests does not have to repeat their house rules.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Account (the owning director)  
**Child entities:** None

## Relationships

- Belongs to the director's Account (`owner_account_id`)
- Is based on a DisciplineProfile (`discipline_profile_id`)
- Optionally references a LandingTable (`landing_table_id`)
- May be the starting point of a ContestConfigurationRevision (`source_preset_id`)

## Fields/Properties

| Field                   | Type        | Required | Default | Description                                                                                             |
| ----------------------- | ----------- | -------- | ------- | ------------------------------------------------------------------------------------------------------- |
| `id`                    | UUIDv7      | Yes      | —       | Primary key                                                                                             |
| `owner_account_id`      | UUIDv7      | Yes      | —       | FK Account of the director who owns the preset                                                          |
| `discipline_profile_id` | UUIDv7      | Yes      | —       | FK DisciplineProfile the preset is for                                                                  |
| `name`                  | string      | Yes      | —       | Name of the preset                                                                                      |
| `description`           | string      | No       | —       | What the preset is for                                                                                  |
| `config`                | JSON        | Yes      | —       | The full resolved settings as `{ "core": {...}, "discipline": {...} }`, in the same shape as a revision |
| `landing_table_id`      | UUIDv7      | No       | —       | FK LandingTable the preset selects                                                                      |
| `created_at`            | timestamptz | Yes      | now     | When the preset was created                                                                             |
| `updated_at`            | timestamptz | Yes      | now     | When the preset was last changed                                                                        |
| `revision`              | int         | Yes      | 0       | Row-level counter for optimistic locking                                                                |

## Invariants and Constraints

- (`owner_account_id`, lower-cased `name`) is unique
- `config` is validated against the discipline profile's definitions and the options document, exactly as a revision is
- Creating a contest from a preset copies it. Later edits or deletion of the preset never change a contest that was created from it
- A preset is for one discipline. A contest created from it has that discipline and cannot change it

## Lifecycle

Created when a director saves a configuration as a preset. Edited or deleted by its owner at any time.

## Privacy and Scope

- Private to the owning director. Part of the director's data, synchronized through the director stream

## Audit and Synchronization

- Changes use revision-based optimistic concurrency
- Deleting a preset creates a tombstone
