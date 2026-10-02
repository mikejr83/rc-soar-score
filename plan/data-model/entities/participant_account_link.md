# ParticipantAccountLink

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md  
**Purpose:** Associates a participant profile with a user account, enabling multiple accounts to link to the same profile over time without rewriting contest history.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (join entity)  
**Child entities:** None

## Relationships

- Join between ParticipatingProfile and Account
- References one ParticipantProfile (participant_profile_id FK)
- References one Account (account_id FK)

## Fields/Properties

| Field                    | Type    | Required | Default | Description                             |
| ------------------------ | ------- | -------- | ------- | --------------------------------------- |
| `id`                     | UUIDv7  | Yes      | —       | Primary key for the link                |
| `participant_profile_id` | UUIDv7  | Yes      | —       | Foreign key to ParticipantProfile       |
| `account_id`             | UUIDv7  | Yes      | —       | Foreign key to Account                  |
| `revision`               | Integer | Yes      | 0       | Revision counter for optimistic locking |

## Invariants and Constraints

- (participant_profile_id, account_id) pair must be unique to prevent duplicate links
- participant_profile_id must reference an existing ParticipantProfile
- account_id must reference an existing Account
- At least one link must exist for a participant to interact through an account

## Lifecycle

Created when an account is first linked to a participant profile. Links may become historical when replacement accounts are used but are not deleted to preserve audit trail.

## Privacy and Scope

- Link metadata is directory-scoped
- Does not contain sensitive personal data; references other entities for data
- Many-to-many relationship allows changed emails or replacement accounts without rewriting contest history

## Audit and Synchronization

- Create operation is idempotent for the same (participant_profile_id, account_id) pair
- Revision counter tracks link-specific mutations
- Link deletions are soft — account associations become inactive rather than removed for audit purposes
