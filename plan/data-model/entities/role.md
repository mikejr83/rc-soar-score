# Role

**Relationship to architecture-requirements:** plan/architecture-requirements/data/teams-roles-models.md  
**Purpose:** A label that catalogs the people involved in a contest. A role is either the single `Pilot` type, which receives scores, or a `NonFlier` type such as a helper, team manager, or official, which is tracked for information and reporting only. Roles are assigned on the ContestParticipation, so every participant in a contest has one, whether or not they are on a team. A role grants no access or authority.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Account (director-owned roles) or none (system roles)  
**Child entities:** None

## Relationships

- Referenced by ContestParticipation (`role_id`)
- Optionally owned by an Account (`owner_account_id`); a system role has no owner

## Fields/Properties

| Field              | Type        | Required | Default | Description                                                                                   |
| ------------------ | ----------- | -------- | ------- | --------------------------------------------------------------------------------------------- |
| `id`               | UUIDv7      | Yes      | —       | Primary key                                                                                   |
| `owner_account_id` | UUIDv7      | No       | null    | FK Account of the director who defined the role. Null for a system role                       |
| `display_name`     | String      | Yes      | —       | Human-readable role name                                                                      |
| `type`             | Enum        | Yes      | —       | `Pilot` or `NonFlier`                                                                         |
| `archived_at`      | timestamptz | No       | null    | When the role was retired from use. An archived role cannot be assigned to new participations |
| `revision`         | Integer     | Yes      | 0       | Revision counter for optimistic locking                                                       |

## Invariants and Constraints

- Exactly one role has type `Pilot`. It is a system role, is the default for every participant, and cannot be changed, archived, or deleted
- System defaults are `Pilot`, `Helper`, and `Team Manager`. System roles cannot be deleted or have their type changed
- A director can add only `NonFlier` roles. Director-owned roles are private to that director
- (`owner_account_id`, lower-cased `display_name`) is unique, with system roles sharing one owner-less namespace
- A role that is in use is archived, not deleted, so the participation's `role_id` always resolves. Renaming a role affects only participations assigned afterwards, because each participation keeps a snapshot of the role's name
- A role carries no permissions. What a person may do comes from invitations and authority, never from the role. An `Official` role is only a label for reports and does not make someone the contest director

## Lifecycle

- System roles are created at application initialization and persist across all contests
- A director creates, renames, and archives their own non-flier roles in system configuration

## Privacy and Scope

- System roles are readable by every director. A director's own roles are visible only to that director and to contests that use them
- The role name is visible to participants in a contest that uses it

## Audit and Synchronization

- Director-owned roles synchronize with the director's data. System roles synchronize down to every client
- Mutation through revision-based optimistic concurrency
- Role changes do not retroactively change a participation's `role_name` or `role_type`
