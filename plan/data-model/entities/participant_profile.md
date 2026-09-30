# ParticipantProfile

**Relationship to architecture-requirements:** plan/architecture-requirements/data/participants.md
**Purpose:** Stores reusable identity and contact data separate from contest-specific participation, enabling a participant's profile to be maintained independently across contests.
**Identifier:** `profileId` (UUIDv7)
**Parent entity:** None (top-level entity)
**Child entities:** None

## Relationships
- Many-to-many with accounts via ParticipantAccountLink
- Participates in zero or more contests via ContestParticipation

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| profileId | UUIDv7 | Yes | — | Primary key for participant profile |
| firstName | String | Yes | — | Participant's given name |
| lastName | String | Yes | — | Participant's family name |
| club | String | No | — | Club affiliation |
| faiNumber | String | No | — | FAI identification number |
| nationalOrgId | String | No | — | National organization ID |
| city | String | No | — | City |
| state | String | No | — | State/province |
| country | String | No | — | Country |
| email | String | No | — | Email address (always private) |
| isShared | Boolean | Yes | false | Whether profile is shared across contests |
| revision | Integer | Yes | 0 | Revision counter for optimistic locking |

## Invariants and Constraints
- Profile must have at least a name (firstName + lastName)
- FAI number, if present, must conform to FAI format
- Email must be unique if isShared is true
- Profile cannot be deleted while still referenced by active ContestParticipation records
- isShared=false profiles are local to a single contest

## Lifecycle
No state machine; created once and mutable throughout.

## Privacy and Scope
- Email is always private regardless of isShared
- Profile can be: director-owned (managed by contest director), local-only (isShared=false, tied to one contest), or shared (isShared=true, reusable across contests)
- Contact details (city/state/country) follow isShared visibility rules

## Audit and Synchronization
- Mutations tracked via revision counter for optimistic concurrency
- Create and update operations are idempotent up to revision
- Profile updates propagate to contest rosters via ContestParticipation references