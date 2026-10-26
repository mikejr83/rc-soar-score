# ParticipantProfile

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md  
**Purpose:** A contest director's own record of a person who takes part in their contests: reusable identity and contact details kept apart from contest-specific participation. A profile belongs to one director and is never shared with another director. Many participants never have an account and exist only as a profile.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Account (the owning director)  
**Child entities:** ModelCatalog

## Relationships

- Belongs to the director's Account (`owner_account_id`)
- Participates in zero or more of the director's contests through ContestParticipation
- Has zero or more models (ModelCatalog, `participant_profile_id`), reusable across the profile's contests
- May be linked to a participant's Account through [ParticipantAccountLink](participant_account_link.md) (backend only). The link relates the profile back to the person's account; it does not share the profile
- May have been created by copying a [ParticipantDirectoryEntry](participant_directory_entry.md) the person offered, in which case the profile is an independent copy

## Fields/Properties

| Field              | Type        | Required | Default | Description                                                    |
| ------------------ | ----------- | -------- | ------- | -------------------------------------------------------------- |
| `id`               | UUIDv7      | Yes      | —       | Primary key for participant profile                            |
| `owner_account_id` | UUIDv7      | Yes      | —       | FK Account of the director who owns and maintains this profile |
| `first_name`       | String      | Yes      | —       | Participant's given name                                       |
| `last_name`        | String      | Yes      | —       | Participant's family name                                      |
| `club`             | String      | No       | —       | Club affiliation                                               |
| `fai_number`       | String      | No       | —       | FAI identification number                                      |
| `national_org_id`  | String      | No       | —       | National organization ID                                       |
| `city`             | String      | No       | —       | City                                                           |
| `state`            | String      | No       | —       | State/province                                                 |
| `country`          | String      | No       | —       | Country                                                        |
| `email`            | String      | No       | —       | Email address. Always private                                  |
| `created_at`       | timestamptz | Yes      | now     | When the profile was created                                   |
| `updated_at`       | timestamptz | Yes      | now     | When the profile was last changed                              |
| `revision`         | Integer     | Yes      | 0       | Revision counter for optimistic locking                        |

## Invariants and Constraints

- A profile has at least a first and last name
- A profile is visible and editable only by its owning director. No other director can see, search, or match it
- Two profiles of the same director may share an email, FAI number, or national organization ID, but the application warns the director about the duplicate (matching uses normalized email first, then FAI number, then national organization ID, never name)
- A profile is never changed by a participant's account. Data moves between an account and a profile only when the director pulls or refreshes it from a directory entry, and the profile stays the director's copy afterwards
- A profile that is referenced by a ContestParticipation cannot be deleted
- A profile has no class, role, team, number, or score; those belong to ContestParticipation

## Lifecycle

No state machine; created once and mutable throughout. It is created when the director adds a participant, or by copying a directory entry. A profile with no participations can be deleted, which creates a tombstone.

## Privacy and Scope

- Private to the owning director. It is part of that director's synchronized data and is never exposed to other directors
- Email is always private and never appears in a public projection
- Published results show a participant in one of two ways. With a confirmed link, they show the participant's AccountPublicProfile, so the participant controls the name displayed. Without one, they show the profile's first and last name and country

## Audit and Synchronization

- Mutations tracked via revision counter for optimistic concurrency
- Create and update operations are idempotent up to revision
- Profile updates are read by contest participations, which hold no copy of identity details
