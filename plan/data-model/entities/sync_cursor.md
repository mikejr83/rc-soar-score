# SyncCursor

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md
**Purpose:** Tracks each client's synchronization position within a contest's mutation stream so the client can resume from where it last synced. This record is owned by an authorized installation and scoped to a contest.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None
**Child entities:** None

## Relationships

Belongs to an authorized installation and a contest (contestId FK). References no entities it owns.

## Fields/Properties

| Field                  | Type                  | Required | Default | Description                                                 |
| ---------------------- | --------------------- | -------- | ------- | ----------------------------------------------------------- |
| `id`                   | UUIDv7                | Yes      | —       | Unique identifier for this cursor record                    |
| `contest_id`           | FK(Contest.contestId) | Yes      | —       | Scope for the cursor                                        |
| `last_synced_sequence` | bigint                | Yes      | 0       | Highest mutation sequence acknowledged by this installation |
| `updated_at`           | timestamp             | Yes      | now()   | Last time the cursor was advanced                           |

## Invariants and Constraints

- `last_synced_sequence` increases monotonically and is never reset.
- There is at most one cursor per (installation, contest) scope.
- The service advances the cursor only after local durable storage of the new position.

## Lifecycle

Created on first sync for a contest installation pair. Updated on each successful sync acknowledgement. Retained indefinitely; never manually edited after creation.

## Privacy and Scope

Visible only to the owning installation.

## Audit and Synchronization

Mutated exclusively by the sync service when acknowledging a successful sync. Updates are idempotent when the same lastSyncedSeq is recorded.
