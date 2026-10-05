# SyncCursor

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md  
**Purpose:** Records how far an installation has synchronized one scope, so it can resume from where it stopped. The service keeps the last position it acknowledged for each installation and scope; the installation keeps its own copy and advances it only after the changes it received are durably stored.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Installation  
**Child entities:** None

## Relationships

- Belongs to an Installation (`installation_id`)
- Scoped to a Contest (`contest_id`) or to the director's data (`owner_account_id`)
- System data is tracked on the installation itself (`Installation.system_data_seq`), not here, because it only comes down. A native installation keeps its own copy under the `System` scope of its local sync positions

## Fields/Properties

| Field                  | Type        | Required    | Default | Description                                                           |
| ---------------------- | ----------- | ----------- | ------- | --------------------------------------------------------------------- |
| `id`                   | UUIDv7      | Yes         | -       | Unique identifier for this cursor record                              |
| `installation_id`      | UUIDv7      | Yes         | -       | FK Installation                                                       |
| `contest_id`           | UUIDv7      | Conditional | -       | FK Contest. Exactly one of `contest_id` and `owner_account_id` is set |
| `owner_account_id`     | UUIDv7      | Conditional | -       | FK Account, for the director's own data stream                        |
| `last_synced_sequence` | bigint      | Yes         | 0       | Highest sequence of the scope that the installation has acknowledged  |
| `last_synced_at`       | timestamptz | No          | -       | When the installation last completed a synchronization of this scope  |
| `updated_at`           | timestamptz | Yes         | now     | When the record was last advanced                                     |

## Invariants and Constraints

- Exactly one of `contest_id` and `owner_account_id` is set
- (`installation_id`, `contest_id`) and (`installation_id`, `owner_account_id`) are each unique: at most one cursor per installation and scope
- `last_synced_sequence` increases monotonically and is never reset
- The cursor is advanced only after the installation has durably stored the returned changes

## Lifecycle

Created the first time an installation synchronizes a scope. Updated on each successful acknowledgement. Retained indefinitely and never edited by hand.

## Privacy and Scope

Visible to the owning director and to the installation. The "last synchronized" shown to the director comes from here.

## Audit and Synchronization

Written only by the service when it acknowledges a synchronization. Recording the same position again is idempotent. Not synced to other installations.
