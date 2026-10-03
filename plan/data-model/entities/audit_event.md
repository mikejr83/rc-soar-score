# Audit Event

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md  
**Purpose:** Immutable change log recording every mutation, state transition, score attempt, and conflict in the system. Sensitive credentials and private message contents are excluded.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None  
**Child entities:** None

## Relationships

- Logs changes to any entity type through `entity_type` and `entity_id`
- Belongs to a Contest (`contest_id`), a director's data (`owner_account_id`), or a publication (`publication_id`), or to none of them for events outside any contest
- Made by an Account (`actor_id`) from an Installation (`installation_id`)
- Immutable and append-only: once created, events are never modified or deleted

## Fields/Properties

| Field                | Type        | Required | Default | Description                                                                                                                                                                                                                                                                                                                                                                                                       |
| -------------------- | ----------- | -------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                 | UUIDv7      | Yes      | -       | Primary key identifying the audit event                                                                                                                                                                                                                                                                                                                                                                           |
| `entity_type`        | String      | Yes      | -       | Type of entity that was changed (for example Contest, ScoreAttempt)                                                                                                                                                                                                                                                                                                                                               |
| `entity_id`          | UUIDv7      | Yes      | -       | Identifier of the changed entity                                                                                                                                                                                                                                                                                                                                                                                  |
| `contest_id`         | UUIDv7      | No       | null    | Containing contest. Null for events outside a contest, and for publication events recorded after the contest was deleted                                                                                                                                                                                                                                                                                          |
| `owner_account_id`   | UUIDv7      | No       | null    | The director whose own data (profiles, roles, models, landing tables, presets) the event concerns                                                                                                                                                                                                                                                                                                                 |
| `publication_id`     | UUIDv7      | No       | null    | Containing publication, for publication, delist, and redaction events. Not a foreign key, so the event is kept if the publication's content is purged                                                                                                                                                                                                                                                             |
| `action`             | Enum        | Yes      | -       | Type of action: `StateTransition`, `ScoreAttempt`, `ScoreReview`, `InvitationIssued`, `InvitationReplaced`, `InvitationRevoked`, `InvitationDeliveryRequested`, `InvitationAccessed`, `InvitationAccessFailed`, `PublicationAttempt`, `DelistRequested`, `DelistDecided`, `DelistWithdrawn`, `Redaction`, `Conflict`, `ConflictAccepted`, `ConflictRejected`, `Deletion`, `Restoration`, `InstallationActivation` |
| `actor_id`           | UUIDv7      | No       | null    | FK Account that acted. Null for an action by the system                                                                                                                                                                                                                                                                                                                                                           |
| `authority`          | Enum        | Yes      | -       | `Director`, `Participant`, `Helper`, `System`, or `Administrator`. A local operator acts as `Director`                                                                                                                                                                                                                                                                                                            |
| `installation_id`    | UUIDv7      | No       | null    | FK Installation the action came from. Null for participant and system actions                                                                                                                                                                                                                                                                                                                                     |
| `device`             | String      | No       | null    | Optional identifier of the originating device                                                                                                                                                                                                                                                                                                                                                                     |
| `base_revision`      | Integer     | No       | null    | Pre-mutation revision (nullable if not applicable)                                                                                                                                                                                                                                                                                                                                                                |
| `resulting_revision` | Integer     | No       | null    | Post-mutation revision (nullable if not applicable)                                                                                                                                                                                                                                                                                                                                                               |
| `server_timestamp`   | timestamptz | Yes      | -       | Time the event was received and logged by the service. Authoritative for ordering                                                                                                                                                                                                                                                                                                                                 |
| `client_timestamp`   | timestamptz | No       | null    | Time the event was generated on the client. Kept for audit only and never used to order or validate events                                                                                                                                                                                                                                                                                                        |
| `reason`             | String      | No       | null    | Optional explanation for the change                                                                                                                                                                                                                                                                                                                                                                               |
| `outcome`            | Enum        | Yes      | Success | Result of the action: `Success`, `Rejected`, or `Conflict`                                                                                                                                                                                                                                                                                                                                                        |

## Invariants and Constraints

- Audit events are immutable once created and append-only; none are modified or deleted
- At most one of `contest_id`, `owner_account_id`, and `publication_id` identifies the scope. A publication event after contest deletion has only `publication_id`
- Client time is retained only as audit information. It is not compared with server time, because client clocks drift
- Sensitive credentials and private message contents are excluded. Redaction events identify the row by `pilot_key` and never contain the redacted details
- `base_revision` and `resulting_revision` capture the optimistic locking state

## Lifecycle

N/A (immutable)

## Privacy and Scope

- Contest and director events are shared with the owning director's installations through synchronization. Participants never receive them
- Events include installation and device identifiers for traceability
- Private fields from the changed entity are not included in audit events

## Audit and Synchronization

- Audit events are themselves synchronized to the director's installations so they hold the full audit trail for their scope
- Events are generated on the client for immediate display and by the service for authoritative ordering
- A change that conflicts with a concurrent change produces an event with outcome `Conflict`
