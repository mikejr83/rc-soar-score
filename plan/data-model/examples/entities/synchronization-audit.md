# Synchronization and Audit

Entity specifications: [Installation](../../entities/installation.md), [InstallationActivation](../../entities/installation_activation.md), [SyncCursor](../../entities/sync_cursor.md), [MutationRecord](../../entities/mutation_record.md), [ConflictRecord](../../entities/conflict_record.md), [Tombstone](../../entities/tombstone.md), [AuditEvent](../../entities/audit_event.md).

## Installation

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c0",
  "owner_account_id": "019c0000-0000-7000-8000-000000000001",
  "label": "Field laptop",
  "platform": "Windows",
  "created_at": "2026-09-01T18:00:00Z",
  "last_seen_at": "2026-10-17T16:41:00Z",
  "last_sync_at": "2026-10-17T16:40:00Z",
  "system_data_seq": 128,
  "revoked_at": null
}
```

## InstallationActivation

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c1",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "installation_id": "019c0000-0000-7000-8000-0000000000c0",
  "activated_by": "019c0000-0000-7000-8000-000000000001",
  "kind": "Initial",
  "activated_at": "2026-09-01T18:05:00Z",
  "ended_at": null
}
```

## SyncCursor

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c2",
  "installation_id": "019c0000-0000-7000-8000-0000000000c0",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_account_id": null,
  "last_synced_sequence": 412,
  "last_synced_at": "2026-10-17T16:40:00Z",
  "updated_at": "2026-10-17T16:40:00Z"
}
```

## MutationRecord

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c3",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_account_id": null,
  "sequence": 405,
  "entity_type": "ScoreAttempt",
  "entity_id": "019c0000-0000-7000-8000-000000000401",
  "base_revision": null,
  "client_mutation_id": "01J9ZM5B2E4G6H8K0N2Q4S6U8W",
  "actor_id": "019c0000-0000-7000-8000-000000000001",
  "authority": "Director",
  "source_installation_id": "019c0000-0000-7000-8000-0000000000c0",
  "source_device": "field-laptop",
  "client_time": "2026-10-17T15:09:58Z",
  "server_acceptance_time": "2026-10-17T15:10:00Z",
  "server_rejection_time": null,
  "payload": {
    "score_placeholder_id": "019c0000-0000-7000-8000-000000000301",
    "raw_components": {
      "time_flown": 585,
      "landing": "019a3c4e-8f2a-7b1c-9d4e-6f5a3b2c1d32"
    }
  },
  "outcome": "Accepted",
  "reason_code": null,
  "error_message": null,
  "depends_on_mutation_id": null
}
```

## ConflictRecord

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c4",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_account_id": null,
  "entity_type": "ScorePlaceholder",
  "entity_id": "019c0000-0000-7000-8000-000000000301",
  "accepted_mutation_id": "019c0000-0000-7000-8000-0000000000c3",
  "competing_mutation_id": "019c0000-0000-7000-8000-0000000000c7",
  "reason_code": "stale_base",
  "reason": "A second device entered a score from an older score revision",
  "requires_action": true,
  "resolution": "Pending",
  "resolution_choice": null,
  "created_at": "2026-10-17T15:12:00Z",
  "resolved_at": null,
  "resolved_by": null
}
```

## Tombstone

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c5",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_account_id": null,
  "entity_type": "Team",
  "entity_id": "019c0000-0000-7000-8000-0000000000e0",
  "status": "Acknowledged",
  "deleted_at": "2026-10-10T19:00:00Z",
  "acknowledged_at": "2026-10-10T19:01:00Z",
  "purge_after": "2027-01-08T19:01:00Z",
  "deletion_reason": "Duplicate team"
}
```

## AuditEvent

```json
{
  "id": "019c0000-0000-7000-8000-0000000000c6",
  "entity_type": "ScoreAttempt",
  "entity_id": "019c0000-0000-7000-8000-000000000401",
  "contest_id": "019c0000-0000-7000-8000-000000000010",
  "owner_account_id": null,
  "publication_id": null,
  "action": "ScoreAttempt",
  "actor_id": "019c0000-0000-7000-8000-000000000001",
  "authority": "Director",
  "installation_id": "019c0000-0000-7000-8000-0000000000c0",
  "device": "field-laptop",
  "base_revision": 0,
  "resulting_revision": 1,
  "server_timestamp": "2026-10-17T15:10:00Z",
  "client_timestamp": "2026-10-17T15:09:58Z",
  "reason": null,
  "outcome": "Success"
}
```
