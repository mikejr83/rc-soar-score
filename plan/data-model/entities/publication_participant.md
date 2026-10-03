# PublicationParticipant

**Relationship to architecture-requirements:** plan/architecture-requirements/data/publication.md, plan/architecture-requirements/data/accounts.md  
**Purpose:** Holds the identifying details of a pilot shown in a publication, separate from the published results themselves. Published results refer to pilots only by an opaque key, so a pilot's details can be removed without touching scores, ranks, or any earlier version of the results. It is also the link that lets a person's results be followed across contests through their public profile.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** PublicationIdentity  
**Child entities:** None

## Relationships

- Belongs to a PublicationIdentity (`publication_id`)
- Referenced from PublicationProjection content by `pilot_key` (a value in the projection, not a foreign key)
- Optionally linked to an AccountPublicProfile (`public_profile_id`) when the pilot is linked to an account
- Optionally remembers the contest participation it was generated from (`source_participation_id`), without a foreign key

## Fields/Properties

| Field                     | Type        | Required | Default               | Description                                                                                                                                        |
| ------------------------- | ----------- | -------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                      | UUIDv7      | Yes      | Generated on creation | Primary key                                                                                                                                        |
| `publication_id`          | UUIDv7      | Yes      | -                     | FK PublicationIdentity                                                                                                                             |
| `pilot_key`               | String      | Yes      | -                     | Opaque key that identifies the pilot inside projection content. Generated for the publication; carries no contest id or personal data              |
| `source_participation_id` | UUIDv7      | No       | -                     | The ContestParticipation this row was generated from, so republishing updates the same row. Not a foreign key. Cleared when the contest is deleted |
| `details`                 | JSON        | No       | -                     | The identifying fields the results display (for example name, club, country). Null once redacted                                                   |
| `public_profile_id`       | UUIDv7      | No       | -                     | FK AccountPublicProfile. Null when the pilot has no linked account, after unlinking, and after redaction                                           |
| `redacted_at`             | timestamptz | No       | -                     | When the details were redacted. Write-once                                                                                                         |
| `created_at`              | timestamptz | Yes      | now                   | When the row was created                                                                                                                           |
| `updated_at`              | timestamptz | Yes      | now                   | When the row was last changed                                                                                                                      |

## Invariants and Constraints

- (`publication_id`, `pilot_key`) is unique
- Projection content identifies pilots by `pilot_key` only. Names, clubs, and other details are never embedded in projection content
- Redaction deletes the details, it does not mask them: `details` is set to null, `public_profile_id` is set to null, and `redacted_at` is set. If `redacted_at` is set, `details` and `public_profile_id` are null
- Redaction is irreversible and write-once. A redacted row is never repopulated, including by later republishing of a contest that is still running or by corrections to the source participant's data
- Scores, ranks, and team totals in the projection are unchanged by redaction. Rendering a redacted pilot shows the fixed text "`<pilot details private>`", which is a display constant and is not stored
- Redaction applies to every version of the publication and everywhere the data leaves, including cached pages and exports
- An account can redact only rows whose `public_profile_id` belongs to its own public profile. A participant with no account has no such link, and redaction for them is performed by a system administrator through the same operation
- `public_profile_id` is set only through a verified link between the participant and an account. It is set when an unclaimed guest account is claimed, and cleared when the account is erased or unlinked
- `source_participation_id` is a plain reference and is set to null when the contest's working data is deleted. After that, the row can no longer be updated by republishing
- Publishing creates rows for new pilots and refreshes `details` for rows that are not redacted

## Lifecycle

1. Created the first time a publish includes the pilot.
2. Refreshed on each republish while the contest exists and the row is not redacted.
3. Redacted when the linked account requests removal of their participation records, or when an administrator redacts it. Redaction is automatic and needs no approval.
4. Retained for as long as the publication is. Deleted only if the publication's content is purged.

## Privacy and Scope

- Public by definition while `details` is present, as part of the published results
- `source_participation_id` is internal and never exposed publicly
- Backend and publication only. Not synced to installations

## Audit and Synchronization

- Redaction records an AuditEvent tied to the publication (`publication_id`), identifying the row by `pilot_key`. The event never contains the redacted details
- Creation and refresh happen as part of publishing and are covered by the projection's own revision history
- Not synced
