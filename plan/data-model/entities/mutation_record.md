# MutationRecord

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md
**Purpose:** Records each client mutation submitted to the service so that mutations can be applied at most once, rejected or accepted deterministically, and audited. Serves as the basis for conflict detection and cursor-based replication.
**Identifier:** `mutationId` (UUIDv7)
**Parent entity:** None (referential only via FKs)
**Child entities:** ConflictRecord (via winner/loser FKs)

## Relationships
References `entityId`/`entityType` of the mutated entity. References `contestId` when the entity is contest-scoped. Referenced by ConflictRecord.winnerMutationId and ConflictRecord.loserMutationId. Audit entries reference the mutation via the same stable ID.

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| mutationId | UUIDv7 | Yes | — | Unique identifier for this mutation record |
| entityType | text | Yes | — | Stable name of the entity type being mutated |
| entityId | text | Yes | — | Stable identifier of the entity being mutated |
| contestId | FK(Contest.contestId) | No | NULL | Scope when the entity belongs to a contest |
| baseRevision | integer | Yes | — | Revision expected when the mutation was created |
| clientMutationId | text | Yes | — | Unique client-side ID for idempotency |
| actorId | FK(User.userId) | Yes | — | User who caused the mutation |
| authority | text | Yes | — | Role/authority of the actor for this mutation |
| sourceInstallation | UUID | Yes | — | Installation that submitted the mutation |
| sourceDevice | UUID | Yes | — | Device that originated the mutation |
| clientTime | timestamp | Yes | — | Timestamp from the client |
| serverAcceptanceTime | timestamp | No | NULL | When the service accepted the mutation |
| serverRejectionTime | timestamp | No | NULL | When the service rejected the mutation |
| payload | jsonb | Yes | — | Entity payload at the time of the mutation (full state or delta) |
| outcome | text | Yes | 'Accepted' | Final disposition: Accepted, Rejected, Conflict |
| errorMessage | text | No | NULL | Explanation for rejections/conflicts |

## Invariants and Constraints
- clientMutationId is globally unique across a contest installation; the service applies each unique client mutation ID at most once.
- Mutations from inactive devices (replaced installations) are rejected and recorded as such.
- Published contests cannot be deleted through a mutation that would otherwise be valid.
- Mutations against a stale baseRevision that conflicts with another accepted value produce a Conflict.
- For authorative data, no implicit last-write-wins resolution is applied to concurrent conflicts; the mutation is surfaced to the relevant authority.

## Lifecycle
Created when a client submits a mutation. Outcome set to Rejected, Accepted, or Conflict based on baseRevision, installation authority, and conflict detection. Retained indefinitely for audit.

## Privacy and Scope
Full payload retained for audit. Read by the owning contest installations and administrators.

## Audit and Synchronization
Mutated only once by the service when computing the outcome. The record itself is append-only and idempotent with respect to repeated submissions of the same clientMutationId.