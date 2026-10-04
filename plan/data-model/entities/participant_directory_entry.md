# ParticipantDirectoryEntry

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md, plan/architecture-requirements/data/accounts.md  
**Purpose:** The basic details a person offers about themselves as a participant, kept on their account. A director running a contest can find a listed entry and copy it into their own ParticipantProfile, so a participant who has taken part before does not have to be typed in again. It is separate from the Account (authentication) and from AccountPublicProfile (what appears in published results). An account that is a director can also have an entry, because the same person may take part in someone else's contest.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Account  
**Child entities:** None

## Relationships

- Belongs to exactly one Account (`account_id`)
- Copied by directors into ParticipantProfile records. The copy has no ongoing dependency, but a [ParticipantAccountLink](participant_account_link.md) records where it came from

## Fields/Properties

| Field                        | Type        | Required | Default               | Description                                                                                                                   |
| ---------------------------- | ----------- | -------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                         | UUIDv7      | Yes      | Generated on creation | Primary key                                                                                                                   |
| `account_id`                 | UUIDv7      | Yes      | -                     | FK Account. Unique                                                                                                            |
| `first_name`                 | String      | Yes      | -                     | Given name                                                                                                                    |
| `last_name`                  | String      | Yes      | -                     | Family name                                                                                                                   |
| `club`                       | String      | No       | -                     | Club affiliation                                                                                                              |
| `fai_number`                 | String      | No       | -                     | FAI identification number                                                                                                     |
| `national_org_id`            | String      | No       | -                     | National organization ID                                                                                                      |
| `city`                       | String      | No       | -                     | City                                                                                                                          |
| `state`                      | String      | No       | -                     | State/province                                                                                                                |
| `country`                    | String      | No       | -                     | Country                                                                                                                       |
| `is_listed`                  | Bool        | Yes      | false                 | Whether directors can find this entry. The participant's opt-in                                                               |
| `email_visible_to_directors` | Bool        | Yes      | false                 | Whether a director can see the account's email. When false the director is only told that an email is available to the system |
| `created_at`                 | timestamptz | Yes      | now                   | When the entry was created                                                                                                    |
| `updated_at`                 | timestamptz | Yes      | now                   | When the entry was last changed                                                                                               |

## Invariants and Constraints

- At most one entry per account (`account_id` is unique)
- Only registered accounts have an entry. Guest, local, and deleted accounts do not
- Only a listed entry (`is_listed`) can be found by a director
- The email is the account's own verified email. It is not stored here, and it never appears in a public projection
- A director lookup is a server-side exact match on normalized email, FAI number, or national organization ID, plus name suggestions. It returns only the allowed fields of listed entries. The server never reveals whether an unlisted account exists
- Data moves from an entry to a director's profile only when the director pulls or refreshes it. The entry never reads from or writes to a director's profile
- A director's ParticipantProfile is never visible to another director through this entity

## Lifecycle

Created when a participant chooses to offer details. Updated by the account holder. Deleted when the account is erased.

## Privacy and Scope

- Backend only, never synchronized to installations
- Visible to its account holder. Directors see only the allowed fields of listed entries, through lookup results
- Not part of any published result. Published results use AccountPublicProfile

## Audit and Synchronization

- Creation, changes, listing, and deletion are recorded in application logs
- A director's pull or refresh is recorded in the director's own audit trail, without the copied values
- Not synced
