# PublicationIdentity

**Relationship to architecture-requirements:** plan/architecture-requirements/data/publication.md  
**Purpose:** Persistent identity record linking a private contest to its published projection; provides stable ownership, claim status, and visibility independent of private contest data.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (top-level)  
**Child entities:** [PublicationProjection](publication_projection.md), [PublicationParticipant](publication_participant.md), [DelistRequest](delist_request.md)

## Relationships

- One PublicationIdentity publishes zero or more PublicationProjection revisions (one-to-many)
- References the source Contest via `contest_id`. The reference is optional and is cleared (`ON DELETE SET NULL`) when the contest's working data is deleted, because the publication outlives the contest
- References its owner through an [AccountPublicProfile](account_public_profile.md) (`owner_public_profile_id`) and never the Account itself
- Has zero or more [PublicationParticipant](publication_participant.md) rows and zero or more [DelistRequest](delist_request.md) rows
- Referenced by AuditEvent (`publication_id`)
- References one current PublicationProjection via `current_projection_id`

## Fields/Properties

| Field                          | Type                              | Required    | Default   | Description                                                                                                                                                              |
| ------------------------------ | --------------------------------- | ----------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`                           | UUIDv7                            | yes         | -         | Stable identifier for the published-contest record                                                                                                                       |
| `contest_id`                   | UUIDv7                            | No          | null      | FK Contest, `ON DELETE SET NULL`. Identifier of the source private contest. Null once the contest is deleted; a publication with no contest can no longer be republished |
| `owner_public_profile_id`      | UUIDv7                            | Conditional | null      | FK AccountPublicProfile. Current owner of the publication. Required when `claim_status` is `Claimed`; null for an unclaimed anonymous publication                        |
| `claim_status`                 | Enum [Unclaimed, Claimed]         | yes         | Unclaimed | Whether the publication has been claimed                                                                                                                                 |
| `verification_email`           | string                            | no          | null      | Verified private email for anonymous publisher                                                                                                                           |
| `visibility`                   | Enum [Unlisted, Public, Delisted] | yes         | Unlisted  | Current visibility of the published projection. The owner switches between `Unlisted` and `Public`. `Delisted` is set only by approval of a DelistRequest                |
| `published_at`                 | datetime                          | no          | null      | Timestamp of first successful publish                                                                                                                                    |
| `current_projection_id`        | UUIDv7                            | no          | null      | FK to the most recent complete PublicationProjection                                                                                                                     |
| `results_hidden_through_round` | Integer                           | No          | null      | Copy of the contest's results-hiding setting. Null when results are not hidden. Otherwise overall scores and placing are shown only through this round                   |
| `results_hidden_at`            | timestamptz                       | No          | null      | When hiding was turned on. Hiding expires 24 hours after this time. Non-null exactly when `results_hidden_through_round` is non-null                                     |
| `revision`                     | Integer                           | Yes         | 0         | Row-level counter for optimistic locking, incremented on every change                                                                                                    |

## Invariants and Constraints

- A published-contest record is a public projection, never a source of private contest data
- Visibility (Unlisted, Public) is independent of publication status and does not change the private contest
- Anonymous publishing requires a verified private email and a non-public anonymous publisher record
- Claiming transfers management without changing public history
- An unclaimed publication has no owner profile and is identified by `verification_email`. Claiming sets `owner_public_profile_id` and `claim_status` together
- The hiding columns mirror the contest's setting and are updated whenever it changes. Once set they expire 24 hours after `results_hidden_at` even if the contest has been deleted. The service applies them when serving standings from the current projection
- `contest_id` is null only after the contest's working data has been deleted. Deleting the contest never deletes the publication
- `Delisted` is set only when a DelistRequest is approved. The owner cannot move a delisted publication back to another visibility. Permanently purging a delisted publication's content is a separate administrator action
- Published contests are retained indefinitely as a permanent public archive; deletion requires a formal delisting process

## Lifecycle

- Initial state: Unclaimed with Unlisted visibility
- Unclaimed -> Claimed: account claims management of the publication
- Visibility can transition between Unlisted and Public at any time after first publish
- Delisting formally removes the publication from public archive (not automatic deletion). The owner asks through a DelistRequest; a system administrator approves, and approval sets visibility to `Delisted`

## Privacy and Scope

- Entity itself is a management wrapper; public accessibility is controlled via `visibility`
- Owner identity, claim status, and verification email are private to the owner
- The projection (separate entity) contains public-facing data once visibility is Public

## Audit and Synchronization

- Ownership changes and claim status transitions are recorded in the publication's audit history as AuditEvents tied to `publication_id`, which survive deletion of the contest
- First successful publish sets `published_at` and `current_projection_id`
- Subsequent successful publishes update `current_projection_id` only (Projection entities are immutable)
- Reapplying the same visibility or claim transition is idempotent
