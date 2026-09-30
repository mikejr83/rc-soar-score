# Account

**Relationship to architecture-requirements:** plan/architecture-requirements/data/accounts.md
**Purpose:** Represents an authenticated person who owns contests, manages director-controlled data, and syncs authorized contests. Supports claiming anonymous publications. Stores identity information and identity-provider subject for authentication.
**Identifier:** `accountId` (UUIDv7)
**Parent entity:** None (top-level)
**Child entities:** None direct; owns contests via foreign key

## Relationships
- Owns zero or more Contests (N:1 from Contest.ownerAccountId to Account.accountId)
- May be linked to one or more Participant profiles via ParticipantAccountLink

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| accountId | UUIDv7 | Yes | Generated on creation | Primary key for the account |
| firstName | String | Yes | None | Account holder's first name |
| lastName | String | Yes | None | Account holder's last name |
| email | String | Yes | None | Account holder's email address; used as candidate link for participant profile matching |
| providerSubject | String | Yes | None | Stable identity-provider subject identifier; authentication key only, not exposed to clients |

## Invariants and Constraints
- `providerSubject` is unique within the installation; identifies account for identity provider matching
- Identity-provider identifiers are authentication keys, not contest ownership references exposed to clients
- Creating an account does not automatically merge or rewrite historical contest participation
- Any match by email is a candidate link subject to ownership and privacy rules

## Lifecycle
None (CRUD operations only)

## Privacy and Scope
- `providerSubject` is private to the installation and identity provider; not exposed to clients
- Account ownership is separate from administration access and participant scoring access
- Email address may be shared with linked participant profiles per privacy rules

## Audit and Synchronization
- Creation, update, and deletion are audited via standard application logs
- Account deletion must handle foreign-key constraints on owned contests
- Account data syncs across installations authorized by the account owner