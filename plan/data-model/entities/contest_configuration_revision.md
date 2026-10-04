# ContestConfigurationRevision

**Relationship to architecture-requirements:** [contest.md](../../architecture-requirements/data/contest.md), [disciplines-and-configuration.md](../../architecture-requirements/data/disciplines-and-configuration.md)  
**Purpose:** One saved version of a contest's configuration: the full resolved settings, the discipline profile they are for, and the landing table in use. Revisions are append-only, so historical results stay explainable when the configuration changes. The settings are defined in [contest-options.md](../contest-options.md).  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Contest  
**Child entities:** None

## Relationships

- Belongs to a Contest (`contest_id`)
- References the DisciplineProfile (`discipline_profile_id`), which pins the exact rules version
- Optionally records the ContestConfigurationPreset it started from (`source_preset_id`), as provenance only
- References the LandingTable in use (`landing_table_id`)
- Created by an Account (`created_by`)
- Linked from ScoreAttempt (for provenance) and stamped on FlightResult, ParticipationStanding, and TeamStanding as the revision they were computed under
- The matrix-affecting settings are copied into each MatrixRevision's draw settings

## Fields/Properties

| Field                   | Type      | Required | Default | Description                                                                                                                    |
| ----------------------- | --------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `id`                    | UUIDv7    | Yes      | —       | Primary key (surrogate)                                                                                                        |
| `contest_id`            | UUIDv7    | Yes      | —       | FK Contest                                                                                                                     |
| `revision_number`       | int       | Yes      | —       | Sequential number of the revision within the contest, starting at 1                                                            |
| `discipline_profile_id` | UUIDv7    | Yes      | —       | FK DisciplineProfile. The same for every revision of a contest                                                                 |
| `source_preset_id`      | UUIDv7    | No       | —       | FK ContestConfigurationPreset the first revision was copied from. Not enforced after the preset changes or is deleted          |
| `config`                | JSON      | Yes      | —       | The full resolved settings as `{ "core": {...}, "discipline": {...} }`, including defaults                                     |
| `landing_table_id`      | UUIDv7    | No       | —       | FK LandingTable the contest uses for landing scores. Starts as the profile's default and may be any table the director can use |
| `created_by`            | UUIDv7    | Yes      | —       | FK Account that created the revision                                                                                           |
| `notes`                 | string    | No       | —       | Free-text notes about the revision                                                                                             |
| `created_at`            | timestamp | Yes      | —       | When the revision was created (UTC)                                                                                            |

## Invariants and Constraints

- (`contest_id`, `revision_number`) is unique. The current revision is the one with the highest number; there is no stored "current" flag
- Revisions are append-only and never edited. Any change creates a new revision that copies the previous one with the edited values
- Revision numbers increase by one and are assigned by the contest's active administration installation. The service checks each new revision against the base revision it was made from
- Every revision of a contest has the same `discipline_profile_id`. The discipline never changes once set
- `config` holds every setting, not only the director's changes, so a revision never changes meaning when a platform default changes. A discipline field is an override when its value differs from the field's default, which is found by comparison and not stored
- `config.core` contains the options in the options document, and `config.discipline` contains the profile's configuration fields. Both are validated against their definitions and dependencies
- The first revision is built from the platform defaults, the profile's `default_options`, and the field defaults, or copied from a preset or a previous contest
- What can change, and when, follows the rules in the options document. The discipline field values and the landing table are fixed once the contest is running. The landing table also locks at the first landing score
- A change to a recalculating setting makes every stored result stale until it is recomputed from the raw data
- Changes are rejected while the administration lock is on, and none are made after the contest is completed

## Lifecycle

1. Created with the first revision when the director chooses the discipline
2. Each saved edit creates a new revision with the next number
3. When the contest is completed the configuration is locked and no new revisions are made

## Privacy and Scope

- Contest data, synchronized through the contest stream. Private to the director
- Not exposed in the public projection, except indirectly through scoring behaviour and the calculation metadata

## Audit and Synchronization

- Each new revision is a mutation with an AuditEvent. Old revisions are never deleted
- Two installations that edit independent settings are merged by key; incompatible edits of the same setting surface as a conflict
