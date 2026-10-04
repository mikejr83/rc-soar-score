# Account

**Relationship to architecture-requirements:** plan/architecture-requirements/data/accounts.md  
**Purpose:** A person's identity within the backend. An account is one of four kinds: a registered user who signs in through an identity provider, a guest created when someone redeems an invitation without having an account, the local account that owns data created offline on an installation, and the single shared deleted-user account that anonymized references point at. Accounts are a backend concern and are not synced to installations. An account is also the root for deciding what is removed when a deletion is requested.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (top-level)  
**Child entities:** [AccountIdentity](account_identity.md), [AccountPublicProfile](account_public_profile.md), [ParticipantDirectoryEntry](participant_directory_entry.md)

## Relationships

- Has zero or more AccountIdentity records. Registered accounts have at least one. Guest, local, and deleted accounts have none until a guest or local account is claimed
- Has zero or one AccountPublicProfile
- Has zero or one ParticipantDirectoryEntry, the details the person offers to directors
- Owns the director's ParticipantProfile records (`ParticipantProfile.owner_account_id`)
- Owns the director's ModelCatalog entries (`ModelCatalog.owner_account_id`)
- Owns zero or more Contests (`Contest.owner_account_id`)
- Linked to participant profiles through ParticipantAccountLink (backend only)
- Referenced as an opaque actor by records inside contests (`created_by`, `finalized_by`, `assessed_by`, `set_by`, `actor_id`, and similar)
- Redeems Invitations (`Invitation.redeemed_by_account_id`)

## Fields/Properties

| Field             | Type        | Required | Default               | Description                                                                                                                                     |
| ----------------- | ----------- | -------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`              | UUIDv7      | Yes      | Generated on creation | Primary key for the account                                                                                                                     |
| `first_name`      | String      | Yes      | None                  | Account holder's first name. Guest accounts take the name the director gave the participant; local and deleted accounts use a fixed placeholder |
| `last_name`       | String      | Yes      | None                  | Account holder's last name, same rules as `first_name`                                                                                          |
| `email`           | String      | No       | None                  | Email address, stored lowercase. Null for local and deleted accounts and for guests who gave none                                               |
| `email_verified`  | Bool        | Yes      | false                 | Snapshot of the identity provider's verified-email claim, refreshed at sign-in. Always false for guest accounts                                 |
| `kind`            | enum        | Yes      | -                     | `registered`, `guest`, `local`, or `deleted`                                                                                                    |
| `status`          | enum        | Yes      | active                | `active` or `archived`. An archived account cannot sign in; its data is retained                                                                |
| `archived_at`     | timestamptz | No       | None                  | When the account was archived                                                                                                                   |
| `is_system_admin` | Bool        | Yes      | false                 | Grants the system administrator persona. Set out of band by the backend; never settable through a client request                                |
| `created_at`      | timestamptz | Yes      | now                   | When the account was created                                                                                                                    |
| `updated_at`      | timestamptz | Yes      | now                   | When the account was last modified                                                                                                              |

## Invariants and Constraints

- Exactly one account has `kind` `deleted`. It is created by the system, has no identity, email, or public profile, and cannot be archived or claimed
- A `registered` account has at least one AccountIdentity. `guest`, `local`, and `deleted` accounts cannot sign in
- `email` is stored in lowercase. Email is unique (case-insensitive) among registered accounts that have one
- An email is a candidate for matching a participant profile only when `email_verified` is true. A director-supplied email on an invitation is never verified until the invitee redeems the emailed link
- Identity-provider identifiers are authentication keys. They live only in AccountIdentity and are never exposed to clients
- Clients never receive Account rows, except an installation's own local account. Records inside contests carry account ids as opaque actor references, and installations do not enforce foreign keys on them. Names for display come from public profiles or from the participant record
- Linking an account to a participant profile never copies account data into the profile. Data moves only when a director pulls or refreshes a directory entry
- Creating an account does not automatically merge or rewrite historical contest participation
- **Claiming:** a guest or local account is claimed into a registered account by re-pointing every reference to it (ownership, actor columns, invitations, participant links) to the registered account. Claiming is one-directional and happens once per account. A registered account is never merged into another account. A guest is claimed only by someone who redeems the invitation or claim link

## Lifecycle

- **Registered:** created at first sign-in or registration together with its identity. `active`, then `archived` when the user closes the account. Archiving retains all data.
- **Guest:** created when an invitation is redeemed. Either claimed into a registered account, or purged 90 days after the contest it was invited to is marked completed or 90 days after that contest's scheduled end date, whichever comes first (for the latest such contest, if it was invited to several). When purged, the records that reference it are re-pointed to the deleted-user account.
- **Local:** exists on a single installation and owns data created offline. Claimed into a registered account when the user registers or signs in.
- **Deletion request:** the user chooses what to remove (see Deletion below). The identity records and the account row are then erased.

## Deletion

A deletion request removes data in the backend only. Data entered by a contest director belongs to that director and is not removed at another person's request. In order:

1. AccountIdentity records are deleted.
2. If the user asked to remove their contest data: the working data of every contest the account owns is deleted. Publications remain with their link to the contest cleared, and a delist request is raised for each (reviewed by a system administrator).
3. If the user asked to remove their participation records: their details in published results are redacted automatically and the public profile is unlinked.
4. ParticipantAccountLink records for the account, and its ParticipantDirectoryEntry, are deleted. The director's participant profiles and participations stay.
5. References to the account from other directors' contests are re-pointed to the deleted-user account.
6. `AccountPublicProfile.account_id` is set to null.
7. The account row is deleted.

## Privacy and Scope

- Private to the backend. Never synced to installations
- Account ownership is separate from administration and scoring access. In the first release a contest has a single owner, officials act on the owner's behalf, and a self-scorer acts through an invitation
- Email is never exposed to other accounts

## Audit and Synchronization

- Account creation, update, archiving, and deletion are recorded in application logs, since account events are not scoped to a contest
- System administrator actions that affect an account are audited
- Not synced. The only account an installation holds is its own local account, which is claimed through the backend
