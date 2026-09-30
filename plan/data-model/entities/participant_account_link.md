# ParticipantAccountLink

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md
**Purpose:** Associates a participant profile with a user account, enabling multiple accounts to link to the same profile over time without rewriting contest history.
**Identifier:** `linkId` (UUIDv7)
**Parent entity:** None (join entity)
**Child entities:** None

## Relationships
- Join between ParticipatingProfile and Account
- References one ParticipantProfile (profileId FK)
- References one Account (accountId FK)

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| linkId | UUIDv7 | Yes | — | Primary key for the link |
| profileId | UUIDv7 | Yes | — | Foreign key to ParticipantProfile |
| accountId | UUIDv7 | Yes | — | Foreign key to Account |
| revision | Integer | Yes | 0 | Revision counter for optimistic locking |

## Invariants and Constraints
- (profileId, accountId) pair must be unique to prevent duplicate links
- profileId must reference an existing ParticipantProfile
- accountId must reference an existing Account
- At least one link must exist for a participant to interact through an account

## Lifecycle
Created when an account is first linked to a participant profile. Links may become historical when replacement accounts are used but are not deleted to preserve audit trail.

## Privacy and Scope
- Link metadata is directory-scoped
- Does not contain sensitive personal data; references other entities for data
- Many-to-many relationship allows changed emails or replacement accounts without rewriting contest history

## Audit and Synchronization
- Create operation is idempotent for the same (profileId, accountId) pair
- Revision counter tracks link-specific mutations
- Link deletions are soft — account associations become inactive rather than removed for audit purposes