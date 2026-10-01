# Audit Event

**Relationship to architecture-requirements:** plan/architecture-requirements/data/synchronization-and-audit.md
**Purpose:** Immutable change log recording every mutation, state transition, score attempt, and conflict in the system. Sensitive credentials and private message contents are excluded.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None
**Child entities:** None

## Relationships

- Logs mutations of any entity type via `entity_type` and `entity_id`
- Optionality: `contest_id` is nullable for non-contest-scoped mutations
- Immutable: Once created, audit events cannot be modified or deleted
- Append-only: New events are added; existing events remain unchanged

## Fields/Properties

| Field                | Type      | Required | Default | Description                                                                                                                                                                                                                           |
| -------------------- | --------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                 | UUIDv7    | Yes      | -       | Primary key identifying the audit event                                                                                                                                                                                               |
| `entity_type`        | String    | Yes      | -       | Type of entity that was mutated (e.g., Pilot, Contest, Score)                                                                                                                                                                         |
| `entity_id`          | UUIDv7    | Yes      | -       | Identifier of the mutated entity                                                                                                                                                                                                      |
| `contest_id`         | UUIDv7    | No       | null    | Containing contest (nullable for non-contest-scoped mutations)                                                                                                                                                                        |
| `action`             | Enum      | Yes      | -       | Type of action: `StateTransition`, `ScoreAttempt`, `ScoreReview`, `InvitationIssued`, `InvitationUsed`, `PublicationAttempt`, `Conflict`, `ConflictAccepted`, `ConflictRejected`, `Deletion`, `Restoration`, `InstallationActivation` |
| `actor_id`           | UUIDv7    | Yes      | -       | Identifier of the entity acting (pilot, official, system)                                                                                                                                                                             |
| `authority`          | String    | Yes      | -       | Role of the actor (e.g., Pilot, Judge, ScoreReviewer, Organizer)                                                                                                                                                                      |
| `installation`       | String    | Yes      | -       | Identifying label of the originating Soar Score installation                                                                                                                                                                          |
| `device`             | String    | No       | null    | Optional identifier of the originating device                                                                                                                                                                                         |
| `base_revision`      | Integer   | No       | null    | Pre-mutation revision (nullable if not applicable)                                                                                                                                                                                    |
| `resulting_revision` | Integer   | No       | null    | Post-mutation revision (nullable if not applicable)                                                                                                                                                                                   |
| `server_timestamp`   | Timestamp | Yes      | -       | Time event was received and logged by the server                                                                                                                                                                                      |
| `client_timestamp`   | Timestamp | Yes      | -       | Time event was generated on the client                                                                                                                                                                                                |
| `reason`             | String    | No       | null    | Optional explanation for the mutation                                                                                                                                                                                                 |
| `outcome`            | Enum      | Yes      | Success | Result of the mutation: `Success`, `Conflict`, `Failed`                                                                                                                                                                               |

## Invariants and Constraints

- Audit events are immutable once created
- Server timestamp must be >= client timestamp
- Events must be append-only; no modification or deletion
- Sensitive credentials and private message contents are excluded
- `base_revision` and `resulting_revision` capture the optimistic locking state

## Lifecycle

N/A (immutable)

## Privacy and Scope

- Audit events are shared across installations via sync
- Events include installation and device identifiers for traceability
- Private fields from the mutated entity are not included in audit events

## Audit and Synchronization

- Audit events are themselves synchronized to other installations to provide full audit trails
- Events are generated both on the client (for immediate display) and by the server (for authoritative ordering)
- Events use optimistic locking with `resulting_revision`
- Events that conflict with concurrent mutations result in `Conflict` outcome
