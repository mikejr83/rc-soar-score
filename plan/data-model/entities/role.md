# Role

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md
**Purpose:** Defines role templates (pilot vs non-flier, system vs director scope, admin/score/read permissions) that are referenced by ContestParticipation to assign participant roles.
**Identifier:** `roleId` (UUIDv7)
**Parent entity:** System or Contest (depending on scope)
**Child entities:** None

## Relationships
- Referenced by ContestParticipation via roleId foreign key

## Fields/Properties
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| roleId | UUIDv7 | Yes | — | Primary key |
| displayName | String | Yes | — | Human-readable role name |
| type | Enum | Yes | — | Role type: Pilot or NonFlier |
| scope | Enum | Yes | — | Scope: System (built-in) or Director (contest-specific) |
| permission | Enum | Yes | — | Permission level: Admin, Score, or Read |
| revision | Integer | Yes | 0 | Revision counter for optimistic locking |

## Invariants and Constraints
- System-scoped roles are shared defaults and cannot be deleted
- Director-scoped roles are contest-specific and may be customized
- Permission must be appropriate for the role type (e.g., Pilot roles are non-flier helpers)
- displayName must be unique within a contest scope
- A role's permission level determines what operations participants with that role may perform

## Lifecycle
- System roles are created at application initialization and persist across all contests
- Director roles are created when a director defines contest-specific roles
- Roles may be updated but system roles retain stable identifiers

## Privacy and Scope
- Role definitions are contest-scoped (or system-scoped for defaults)
- Role name and permission level are visible to all participants in the contest

## Audit and Synchronization
- Mutation through revision-based optimistic concurrency
- Role updates do not retroactively affect existing participation links