# MutationRecord

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md, plan/architecture-requirements/offline-synchronization.md  
**Purpose:** Records one change made to a synchronizable entity, from the request that made it to the service's decision. It lets the service apply each change at most once, accept or reject it deterministically, order accepted changes in a per-scope sequence that clients pull from, and audit what happened. On a client it also serves as the outbox of changes not yet acknowledged.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (referential only through FKs)  
**Child entities:** ConflictRecord (through its accepted and competing mutation references)

## Relationships

- Belongs to exactly one sync scope: a Contest (`contest_id`) or a director's data (`owner_account_id`)
- References the changed entity by `entity_type` and `entity_id`
- Made by an Account (`actor_id`) from an Installation (`source_installation_id`)
- May depend on another MutationRecord (`depends_on_mutation_id`), for example a score on the matrix revision it references
- Referenced by ConflictRecord

## Fields/Properties

| Field                    | Type        | Required    | Default | Description                                                                                                                                                                                              |
| ------------------------ | ----------- | ----------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                     | UUIDv7      | Yes         | -       | Primary key                                                                                                                                                                                              |
| `contest_id`             | UUIDv7      | Conditional | -       | FK Contest, for a change to contest data. Exactly one of `contest_id` and `owner_account_id` is set                                                                                                      |
| `owner_account_id`       | UUIDv7      | Conditional | -       | FK Account, for a change to a director's own data (profiles, roles, models, landing tables, presets)                                                                                                     |
| `sequence`               | bigint      | No          | -       | Position in the scope's sequence, assigned by the service when the change is accepted. Null until then. Strictly increasing and unique within the scope                                                  |
| `entity_type`            | text        | Yes         | -       | Stable name of the entity type that was changed                                                                                                                                                          |
| `entity_id`              | UUIDv7      | Yes         | -       | Identifier of the changed entity                                                                                                                                                                         |
| `base_revision`          | integer     | No          | -       | Revision the change was based on. Null for a creation                                                                                                                                                    |
| `client_mutation_id`     | text        | Yes         | -       | Unique request identifier from the client, used for idempotency                                                                                                                                          |
| `actor_id`               | UUIDv7      | No          | -       | FK Account that made the change. Null for a change by the system                                                                                                                                         |
| `authority`              | enum        | Yes         | -       | `Director`, `Participant`, `Helper`, `System`, or `Administrator`. A local operator acts as `Director`                                                                                                   |
| `source_installation_id` | UUIDv7      | No          | -       | FK Installation the change came from. Null for a participant submission or a change made by the service itself                                                                                           |
| `source_device`          | text        | No          | -       | Opaque identifier of the device, for audit                                                                                                                                                               |
| `client_time`            | timestamptz | Yes         | -       | Time reported by the client. Kept for audit only; the service never uses it to order or resolve changes                                                                                                  |
| `server_acceptance_time` | timestamptz | No          | -       | When the service accepted the change                                                                                                                                                                     |
| `server_rejection_time`  | timestamptz | No          | -       | When the service rejected the change                                                                                                                                                                     |
| `payload`                | jsonb       | Yes         | -       | The entity state or delta at the time of the change                                                                                                                                                      |
| `outcome`                | enum        | Yes         | Pending | `Pending` (still in a client outbox), `Accepted`, `Rejected`, `Conflict`, or `Skipped` (not attempted because a mutation it depends on failed)                                                           |
| `reason_code`            | text        | No          | -       | Machine-readable reason for a rejection, conflict, or skip, for example `stale_base`, `inactive_installation`, `unknown_matrix_revision`, `entity_deleted`, `unique_violation`, `locked`, `unauthorized` |
| `error_message`          | text        | No          | -       | Human-readable explanation of a rejection or conflict                                                                                                                                                    |
| `depends_on_mutation_id` | UUIDv7      | No          | -       | FK MutationRecord this change depends on                                                                                                                                                                 |

## Invariants and Constraints

- Exactly one of `contest_id` and `owner_account_id` is set
- (`contest_id`, `client_mutation_id`) is unique within a contest, and (`owner_account_id`, `client_mutation_id`) within a director's data. The service applies each unique request at most once, and a retry returns the original outcome
- `sequence` is set only on `Accepted` changes, and clients pull accepted changes after their cursor in sequence order
- Every accepted change has a MutationRecord, including those the service makes itself, such as the placeholders created when a matrix revision is finalized and a participant's accepted score. A client therefore receives every change by pulling mutations after its cursor
- Derived values are never mutations. They are recomputed, not synchronized
- Changes are processed one at a time and each is atomic. One rejected change does not roll back the others in a batch. A change whose dependency failed is `Skipped` and is retried after its dependency is pushed again
- A change from an installation with no open activation for the contest is `Rejected` with `inactive_installation`
- A change with a stale `base_revision` is classified as an automatic merge, a director decision (`Conflict`), or an invalid change (`Rejected`). Last-write-wins is never used for authoritative data
- A change that breaks a unique key, such as two offline moves into the same lane, is `Conflict` with `unique_violation`, and the service creates a ConflictRecord that needs action
- A change to a tombstoned entity is `Rejected` with `entity_deleted`
- A score against an unknown matrix revision or group is `Rejected` with `unknown_matrix_revision` or `unknown_flight_group`. The client keeps it in its outbox and pushes the matrix revision first on retry
- Deleting a contest is an ordinary mutation. Publishing does not prevent it, and the published record is unaffected
- Records are append-only. The outcome and times are set once by the service

## Lifecycle

Created `Pending` on the client when a change is made. The service sets the outcome and, when accepted, the sequence. Retained indefinitely for audit.

## Privacy and Scope

- The full payload is retained for audit. Read by the owning director's installations and by administrators
- Participant installations receive only the changes they are authorized to see

## Audit and Synchronization

- Written by the service when it decides a change. The client keeps its own `Pending` rows until acknowledged
- Idempotent for repeated submissions of the same `client_mutation_id`
