# ParticipantAccountLink

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md  
**Purpose:** Relates a director's participant profile back to the account of the person it describes. It is how a participant who creates an account can track their results across contests held by different directors, and how a published result reaches the participant's public profile. It does not share the profile. Several accounts can be linked to one profile over time, so a changed email or replacement account never rewrites contest history.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (join entity)  
**Child entities:** None

## Relationships

- Joins one [ParticipantProfile](participant_profile.md) (`participant_profile_id`) and one Account (`account_id`)
- The account may belong to a participant, a director, or both. A director who also takes part in another director's contest is linked like any participant

## Fields/Properties

| Field                    | Type        | Required | Default | Description                                                                                                                                                                              |
| ------------------------ | ----------- | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                     | UUIDv7      | Yes      | —       | Primary key for the link                                                                                                                                                                 |
| `participant_profile_id` | UUIDv7      | Yes      | —       | Foreign key to ParticipantProfile                                                                                                                                                        |
| `account_id`             | UUIDv7      | Yes      | —       | Foreign key to Account                                                                                                                                                                   |
| `status`                 | Enum        | Yes      | —       | `Candidate` (a suggested match the participant has not confirmed), `Confirmed`, or `Ended` (replaced or withdrawn)                                                                       |
| `origin`                 | Enum        | Yes      | —       | How the link arose: `EmailMatch` (a verified account email equals the profile's email), `DirectoryPull` (a director copied the participant's directory entry), or `InvitationRedemption` |
| `created_at`             | timestamptz | Yes      | now     | When the link was created                                                                                                                                                                |
| `confirmed_at`           | timestamptz | No       | null    | When the link became `Confirmed`                                                                                                                                                         |
| `ended_at`               | timestamptz | No       | null    | When the link ended                                                                                                                                                                      |
| `revision`               | Integer     | Yes      | 0       | Revision counter for optimistic locking                                                                                                                                                  |

## Invariants and Constraints

- (`participant_profile_id`, `account_id`) is unique
- A profile has at most one `Confirmed` link at a time. Linking a replacement account ends the earlier link
- A link created from a verified email match starts as `Candidate` and becomes `Confirmed` only when the participant confirms it. A `DirectoryPull` link is `Confirmed` on creation, because listing in the directory is the participant's consent. An `InvitationRedemption` link is `Confirmed` on creation, because the director's invitation identifies the person
- An email match uses a verified account email only. A director never learns from a `Candidate` that the person has an account
- Linking never copies account data into the profile, and never merges or rewrites the profile or any contest participation

## Lifecycle

- `Candidate` -> `Confirmed` -> `Ended`. A `Candidate` the participant declines is `Ended`
- Ended links are kept, so history stays explainable. They are deleted only when the account is erased, as described in the Account entity

## Privacy and Scope

- Backend only. Never synchronized to installations
- Contains no personal data itself; it references other entities
- Visible to the account holder and to system administrators

## Audit and Synchronization

- Creating, confirming, and ending a link are recorded in application logs and, where they affect a publication, as publication events
- Creating a link is idempotent for the same (`participant_profile_id`, `account_id`) pair
- Not synced. The installation learns only what it needs through the directory pull
