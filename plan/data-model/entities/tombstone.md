# Tombstone

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md  
**Purpose:** Records a deleted entity in a way that synchronizes. A tombstone stops an older change from recreating a record that was deleted while another installation was offline. It is kept for a limited time after the server confirms the deletion.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None  
**Child entities:** None

## Relationships

- Belongs to one sync scope: a Contest (`contest_id`) or a director's data (`owner_account_id`)
- References the deleted entity by `entity_type` and `entity_id`
- A deleted contest's own tombstone lives in the director's data scope, because the contest's stream goes away with it

## Fields/Properties

| Field              | Type        | Required    | Default | Description                                                                                      |
| ------------------ | ----------- | ----------- | ------- | ------------------------------------------------------------------------------------------------ |
| `id`               | UUIDv7      | Yes         | -       | Primary key                                                                                      |
| `contest_id`       | UUIDv7      | Conditional | -       | FK Contest. Exactly one of `contest_id` and `owner_account_id` is set                            |
| `owner_account_id` | UUIDv7      | Conditional | -       | FK Account, for a deletion in the director's own data                                            |
| `entity_type`      | text        | Yes         | -       | The type of entity that was deleted                                                              |
| `entity_id`        | UUIDv7      | Yes         | -       | The identifier of the deleted entity                                                             |
| `status`           | enum        | Yes         | Pending | `Pending` (not yet acknowledged by the server) or `Acknowledged`                                 |
| `deleted_at`       | timestamptz | Yes         | -       | When the entity was deleted, in UTC, as reported by the deleting installation. For audit only    |
| `acknowledged_at`  | timestamptz | No          | -       | When the server acknowledged the deletion (server time)                                          |
| `purge_after`      | timestamptz | No          | -       | `acknowledged_at` plus 90 days. After this the tombstone may be removed. Null until acknowledged |
| `deletion_reason`  | text        | No          | -       | Optional reason, which may be private to the deleting client                                     |

## Invariants and Constraints

- Exactly one of `contest_id` and `owner_account_id` is set
- (`entity_type`, `entity_id`) is unique: one tombstone per deleted entity
- Status moves only from `Pending` to `Acknowledged`
- A mutation against a tombstoned entity is rejected with `entity_deleted`, so an older change cannot recreate it
- A tombstone is kept for 90 days after the server acknowledges the deletion. There is one rule for every scope, because the local archive flag never reaches the server
- Deleting a contest also deletes its contest data, its conflict records, and the tombstones inside it. The contest's own tombstone remains for the retention period so other installations learn of the deletion
- Restoring an entity after a tombstone was created creates a new revision, and the tombstone stays as history

## Lifecycle

```plaintext
Pending -> Acknowledged -> removed after purge_after
```

## Privacy and Scope

- Tombstone metadata (type, id, times) is shared across the owner's installations
- `deletion_reason` may be private to the deleting client
- Entity-specific privacy is governed by the original entity

## Audit and Synchronization

- Creating a tombstone is a mutation that is replicated to the server, which acknowledges it
- Creation is idempotent by (`entity_type`, `entity_id`)
- Deleting a published contest creates a tombstone like any other deletion. The published record is unaffected
