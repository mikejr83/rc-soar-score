# ImportProvenance

**Relationship to architecture-requirements:** none yet; decided in docs/adr/0006-gliderscore-import-persistence.md  
**Purpose:** Records where an imported entity came from: which source system, which source keys, which file and which import run. It lets a later import phase find the contest an earlier phase created, and lets the application refuse a second import of the same competition. It never changes how the entity behaves, is never edited, and is never used for matching.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (refers to the stamped entity by type and id)  
**Child entities:** None

## Relationships

- Points at one Contest, ContestParticipation, MatrixRevision or ParticipantProfile through (`stamped_entity_type`, `stamped_entity_id`). There is no foreign key on the stamped entity, because the three types live in three tables
- Belongs to the importing director's Account (`owner_account_id`), which is the synchronization scope
- Rows for a contest or its participations also carry `contest_id`, so an export and a contest delete find them. Rows for profiles have no contest

## Fields/Properties

| Field                 | Type     | Required | Default | Description                                                                                                                                                                                              |
| --------------------- | -------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                  | UUIDv7   | Yes      | —       | Primary key                                                                                                                                                                                              |
| `owner_account_id`    | UUIDv7   | Yes      | —       | FK Account of the importing director: the signed-in account, otherwise the installation's Local account (re-pointed when that is claimed)                                                                |
| `contest_id`          | UUIDv7   | No       | —       | Not a foreign key (director data); set for `Contest` and `ContestParticipation` rows, absent for `ParticipantProfile` rows. Deleted with the contest                                                     |
| `stamped_entity_type` | String   | Yes      | —       | `Contest`, `ContestParticipation`, `MatrixRevision` or `ParticipantProfile`                                                                                                                              |
| `stamped_entity_id`   | UUIDv7   | Yes      | —       | The stamped entity                                                                                                                                                                                       |
| `source_system`       | String   | Yes      | —       | `gliderscore`                                                                                                                                                                                            |
| `source_keys`         | JSON     | Yes      | —       | Whole-number source keys: `comp_no` for a contest, `comp_no` and `pilot_no` for a participation, `pilot_no` for a profile. Stored in canonical form                                                      |
| `source_values`       | JSON     | No       | —       | `Contest` rows only: source values that have no Soar Score field and are kept for review and later phases, for example `lane_count` and `landing_table_no`                                               |
| `file_fingerprint`    | String   | Yes      | —       | Hash of the source file, the same for every row of one import                                                                                                                                            |
| `dedupe_key`          | String   | No       | —       | `Contest` rows only: `<source_system>:<file_fingerprint>:<comp_no>`                                                                                                                                      |
| `import_operation_id` | UUIDv7   | Yes      | —       | One id per import run, shared by every row it wrote                                                                                                                                                      |
| `tool_version`        | String   | Yes      | —       | Importer version that wrote the row                                                                                                                                                                      |
| `imported_at`         | DateTime | Yes      | —       | UTC                                                                                                                                                                                                      |
| `revision`            | Integer  | Yes      | 0       | Revision counter for optimistic locking. The app never edits a stamp, so it normally stays 0; it is revisioned so a stamp syncs and deletes like other director data, and a later import may re-save one |

## Invariants and Constraints

- (`owner_account_id`, `dedupe_key`) is unique where `dedupe_key` is set: a director imports a competition of a file once. The importer treats a violation as "already imported" and rolls back that competition
- Only `Contest` rows carry `dedupe_key` and `source_values`. `ParticipantProfile` rows have no `contest_id`; `Contest`, `ContestParticipation` and `MatrixRevision` rows must have one, and a `Contest` row stamps its own contest
- `stamped_entity_type` is one of `Contest`, `ContestParticipation`, `MatrixRevision`, `ParticipantProfile` and `source_system` is `gliderscore`; the model rejects anything else, so a new source or type is a deliberate change here, in the model and in the ADR
- A contest, participation or matrix revision has at most one stamp (unique index on `stamped_entity_type` and `stamped_entity_id`, partial: not for profiles); a profile has at most one per import operation (unique index on `stamped_entity_id` and `import_operation_id`). Read them with `listForEntity`
- `source_keys` are whole numbers in canonical form (sorted keys, plain decimals, no whitespace), so equal keys compare equal as text. The model rejects anything else and stores the keys sorted. A `Contest` row has exactly `comp_no`, a `ContestParticipation` row `comp_no` and `pilot_no`, a `ParticipantProfile` row `pilot_no`
- When set, `dedupe_key` must equal `<source_system>:<file_fingerprint>:<comp_no>` of the same row
- A `MatrixRevision` row (phase C) has a `contest_id`, `comp_no` and `task_no` as source keys, and `source_values` with the round range and group count (and the `SeqNo` positions for a competition with lane count 0). There is no stamp per assignment. At most one stamp per matrix revision
- Never shown as editable data and never takes part in matching profiles

## Lifecycle

- Created by the import in the same transaction as the entity (profiles are written once per import operation, before the per-competition transactions)
- Deleting a contest deletes its `Contest` and `ContestParticipation` stamps, which frees the dedupe key so the competition can be imported again. Profile stamps belong to the director's participants list and stay
- Phase A profiles have no row; a later import adds one when it matches them by the phase A rules

## Privacy and Scope

- Holds source row numbers and a file hash, no names or contact details

## Audit and Synchronization

- Director data: synchronizes through the director's stream, whatever the stamped entity is, and the contest's and participations' rows travel in a `.rcsoar` export with the contest; profile rows do not, they stay with the director's participants list
- Mutation through revision-based optimistic concurrency
