# MutationRecord

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md  
**Purpose:** Records each client mutation submitted to the service so that mutations can be applied at most once, rejected or accepted deterministically, and audited. Serves as the basis for conflict detection and cursor-based replication.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (referential only via FKs)  
**Child entities:** ConflictRecord (via winner/loser FKs)

## Relationships

References `entity_id`/`entity_type` of the mutated entity. References `contest_id` when the entity is contest-scoped. Referenced by ConflictRecord.winnerMutationId and ConflictRecord.loserMutationId. Audit entries reference the mutation via the same stable ID.

## Fields/Properties

| Field                    | Type                  | Required | Default    | Description                                                      |
| ------------------------ | --------------------- | -------- | ---------- | ---------------------------------------------------------------- |
| `id`                     | UUIDv7                | Yes      | —          | Unique identifier for this mutation record                       |
| `entity_type`            | text                  | Yes      | —          | Stable name of the entity type being mutated                     |
| `entity_id`              | text                  | Yes      | —          | Stable identifier of the entity being mutated                    |
| `contest_id`             | FK(Contest.contestId) | No       | NULL       | Scope when the entity belongs to a contest                       |
| `base_revision`          | integer               | Yes      | —          | Revision expected when the mutation was created                  |
| `client_mutation_id`     | text                  | Yes      | —          | Unique client-side ID for idempotency                            |
| `actor_id`               | FK(User.userId)       | Yes      | —          | User who caused the mutation                                     |
| `authority`              | text                  | Yes      | —          | Role/authority of the actor for this mutation                    |
| `source_installation`    | UUID                  | Yes      | —          | Installation that submitted the mutation                         |
| `source_device`          | UUID                  | Yes      | —          | Device that originated the mutation                              |
| `client_time`            | timestamp             | Yes      | —          | Timestamp from the client                                        |
| `server_acceptance_time` | timestamp             | No       | NULL       | When the service accepted the mutation                           |
| `server_rejection_time`  | timestamp             | No       | NULL       | When the service rejected the mutation                           |
| `payload`                | jsonb                 | Yes      | —          | Entity payload at the time of the mutation (full state or delta) |
| `outcome`                | text                  | Yes      | 'Accepted' | Final disposition: Accepted, Rejected, Conflict                  |
| `error_message`          | text                  | No       | NULL       | Explanation for rejections/conflicts                             |

## Invariants and Constraints

- `client_mutation_id` is globally unique across a contest installation; the service applies each unique client mutation ID at most once.
- Mutations from inactive devices (replaced installations) are rejected and recorded as such.
- Published contests cannot be deleted through a mutation that would otherwise be valid.
- Mutations against a stale `base_revision` that conflicts with another accepted value produce a Conflict.
- For authorative data, no implicit last-write-wins resolution is applied to concurrent conflicts; the mutation is surfaced to the relevant authority.

## Lifecycle

Created when a client submits a mutation. Outcome set to Rejected, Accepted, or Conflict based on baseRevision, installation authority, and conflict detection. Retained indefinitely for audit.

## Privacy and Scope

Full payload retained for audit. Read by the owning contest installations and administrators.

## Audit and Synchronization

Mutated only once by the service when computing the outcome. The record itself is append-only and idempotent with respect to repeated submissions of the same `client_mutation_id`.
