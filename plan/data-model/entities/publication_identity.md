# PublicationIdentity

**Relationship to architecture-requirements:** plan/architecture-requirements/data/publication.md  
**Purpose:** Persistent identity record linking a private contest to its published projection; provides stable ownership, claim status, and visibility independent of private contest data.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (top-level)  
**Child entities:** PublicationProjection

## Relationships

- One PublicationIdentity publishes zero or more PublicationProjection revisions (one-to-many)
- References one Contest via `contest_id`
- References one Account via `account_id`
- References one current PublicationProjection via `current_projection_id`

## Fields/Properties

| Field                   | Type                           | Required | Default   | Description                                          |
| ----------------------- | ------------------------------ | -------- | --------- | ---------------------------------------------------- |
| `id`                    | UUIDv7                         | yes      | -         | Stable identifier for the published-contest record   |
| `contest_id`            | UUIDv7                         | yes      | -         | Identifier of the source private contest             |
| `account_id`            | UUIDv7                         | yes      | -         | Current owner of the publication                     |
| `claim_status`          | Enum [Unclaimed, Claimed]      | yes      | Unclaimed | Whether the publication has been claimed             |
| `verification_email`    | string                         | no       | null      | Verified private email for anonymous publisher       |
| `visibility`            | Enum [Private, Hidden, Public] | yes      | Private   | Current visibility of the published projection       |
| `published_at`          | datetime                       | no       | null      | Timestamp of first successful publish                |
| `current_projection_id` | UUIDv7                         | no       | null      | FK to the most recent complete PublicationProjection |

## Invariants and Constraints

- A published-contest record is a public projection, never a source of private contest data
- Visibility (Private, Hidden, Public) is independent of publication status and does not change the private contest
- Anonymous publishing requires a verified private email and a non-public anonymous publisher record
- Claiming transfers management without changing public history
- Published contests are retained indefinitely as a permanent public archive; deletion requires a formal delisting process

## Lifecycle

- Initial state: Unclaimed with Private visibility
- Unclaimed -> Claimed: account claims management of the publication
- Visibility can transition between Private, Hidden, and Public at any time after first publish
- Delisting formally removes the publication from public archive (not automatic deletion)

## Privacy and Scope

- Entity itself is a management wrapper; public accessibility is controlled via `visibility`
- Owner identity, claim status, and verification email are private to the owner
- The projection (separate entity) contains public-facing data once visibility is Public

## Audit and Synchronization

- Ownership changes and claim status transitions are recorded in the publication's audit history
- First successful publish sets `published_at` and `current_projection_id`
- Subsequent successful publishes update `current_projection_id` only (Projection entities are immutable)
- Reapplying the same visibility or claim transition is idempotent
