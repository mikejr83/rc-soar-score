# AccountPublicProfile

**Relationship to architecture-requirements:** plan/architecture-requirements/data/accounts.md, plan/architecture-requirements/data/publication.md
**Purpose:** The public stand-in for an account. Publications and result history reference this record and never the account itself, and it holds only the information the account chose to make public. Unlinking it from the account detaches the person from published data while leaving the public record intact.
**Identifier:** `id` (UUIDv7)
**Parent entity:** Account (optional; null once unlinked)
**Child entities:** None

## Relationships

- Optionally belongs to an Account (`account_id`); null after the account is deleted or the profile is unlinked
- Referenced by PublicationIdentity as the publication's owner
- Referenced by PublicationParticipant as the link that supports a person's results over time

## Fields/Properties

| Field          | Type        | Required | Default               | Description                       |
| -------------- | ----------- | -------- | --------------------- | --------------------------------- |
| `id`           | UUIDv7      | Yes      | Generated on creation | Primary key, used in publications |
| `account_id`   | UUIDv7      | No       | -                     | FK Account. Null once unlinked    |
| `display_name` | String      | Yes      | -                     | Name shown in public results      |
| `created_at`   | timestamptz | Yes      | now                   | When the profile was created      |

Additional public fields (for example club or country) are added here only as an account explicitly chooses to make them public.

## Invariants and Constraints

- Created when an account's information is first needed in a publication (as a publication owner, or when a participant is linked to the account)
- Contains only information the account has deemed public
- At most one public profile per account (unique `account_id` where not null)
- Publications never reference the Account directly
- Unlinking sets `account_id` to null and never changes published results
- A claimed guest account's links are re-pointed to the registered account's public profile as part of claiming

## Lifecycle

Created on first public use. Updated when the account changes what it makes public. Unlinked (not deleted) when the account is deleted, because publications still reference it.

## Privacy and Scope

- Public by definition; contains no private account data
- Never contains email, identity-provider identifiers, or archive status

## Audit and Synchronization

- Creation, changes, and unlinking are recorded in application logs and as publication events where they affect a publication
- Lives with the backend and the publication. It is not part of any contest's synced data
