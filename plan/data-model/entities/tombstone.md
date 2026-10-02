# Tombstone

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md
**Purpose:** Records deleted entities in a way that is synchronizable across installations. Local deletion creates a tombstone until the deletion is acknowledged on the server. Tombstones prevent older changes from recreating deleted records.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None
**Child entities:** None

## Relationships

- References any entity type by `entity_type` and `entity_id`
- Optionality: `contest_id` is nullable for non-contest-scoped entities
- Tombstone is retained for 90 days after deletion, or until contest archiving plus 90 days

## Fields/Properties

| Field             | Type      | Required | Default       | Description                                                                              |
| ----------------- | --------- | -------- | ------------- | ---------------------------------------------------------------------------------------- |
| `id`              | UUIDv7    | Yes      | -             | Primary key identifying the tombstone record                                             |
| `entity_type`     | String    | Yes      | -             | The type of entity being tombstoned (e.g., Pilot, Contest, Participation)                |
| `entity_id`       | UUIDv7    | Yes      | -             | The identifier of the entity being tombstoned                                            |
| `contest_id`      | UUIDv7    | No       | null          | The contest this tombstone is associated with (nullable for non-contest-scoped entities) |
| `status`          | Enum      | Yes      | PendingDelete | Status of the tombstone: `PendingDelete`, `Acknowledged`                                 |
| `deleted_at`      | Timestamp | Yes      | -             | The time the entity was deleted (client-local time)                                      |
| `deletion_reason` | String    | No       | null          | Optional reason for deletion                                                             |

## Invariants and Constraints

- Status transitions: `PendingDelete` → `Acknowledged`
- A tombstone must exist before an older mutation can recreate the same `entity_id`
- Tombstones are retained for 90 days after deletion
- For contest-scoped entities, tombstones are retained until contest archiving plus 90 days
- `entity_type` and `entity_id` must match an existing or previously existing entity

## Lifecycle

```plaintext
PendingDelete -> Acknowledged
```

## Privacy and Scope

- Tombstone metadata (type, ID, timestamps) is shared across installations
- `deletion_reason` may be private to the deleting client
- Entity-specific privacy is governed by the original entity

## Audit and Synchronization

- Creating a tombstone is a mutation that must be replicated to the server
- Server acknowledges tombstone via `Acknowledged` status
- Tombstone creation is idempotent by `(entity_type, entity_id)` pair
- Restoring an entity after tombstone creation creates a new revision; the tombstone remains as historical record
