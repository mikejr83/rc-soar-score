# Contest

**Relationship to architecture-requirements:** plan/architecture-requirements/data/contest.md
**Purpose:** The private source-of-truth aggregate for one radio-controlled soaring event. Stores identity, location, schedule, configuration state, and all derived scoring state.
**Identifier:** `id` (UUIDv7)
**Parent entity:** None (top-level aggregate)
**Child entities:** ConfigurationRevisions (1:N), MatrixRevisions (1:N), Participants/ParticipationLinks (1:N), ScorePlaceholders (1:N), AuditEvents (1:N); has one SyncCursor; has one PublicationIdentity

## Relationships

- Optional Account owner (0:1 from Contest.owner_account_id to Account.id)
- One SyncCursor per contest (1:1)
- One PublicationIdentity per contest (1:1)
- Multiple ConfigurationRevisions (1:N), MatrixRevisions (1:N)
- Multiple Participants/ParticipationLinks, ScorePlaceholders, AuditEvents (1:N)

## Fields/Properties

| Field              | Type     | Required | Default               | Description                                      |
| ------------------ | -------- | -------- | --------------------- | ------------------------------------------------ |
| id                 | UUIDv7   | Yes      | Generated on creation | Primary key; stable event identifier             |
| name               | String   | Yes      | None                  | Contest name                                     |
| start_date_time    | DateTime | Yes      | None                  | Start date/time in contest's timezone            |
| end_date_time      | DateTime | Yes      | None                  | End date/time in contest's timezone              |
| timezone           | String   | Yes      | None                  | IANA timezone name; stored at creation           |
| host               | String   | No       | None                  | Host/venue name                                  |
| city               | String   | No       | None                  | City name                                        |
| state              | String   | No       | None                  | State/province name                              |
| country            | String   | No       | None                  | Country name                                     |
| owner_account_id   | UUIDv7   | No       | None                  | FK to Account; null for anonymous/local contests |
| lifecycle_state    | Enum     | Yes      | Created               | Created, Configuring, Ready, Running, Completed  |
| scoring_access     | Enum     | Yes      | Closed                | Closed, Open                                     |
| admin_lock         | Enum     | Yes      | Unlocked              | Unlocked, Locked                                 |
| publication_status | Enum     | Yes      | Unpublished           | Unpublished, Published                           |
| visibility         | Enum     | Yes      | Private               | Private, Hidden, Public                          |
| local_archive      | Boolean  | Yes      | false                 | Local archive flag                               |
| deletion_status    | Enum     | Yes      | None                  | None, PendingDelete, Restored, Deleted           |
| revision           | Integer  | Yes      | 1                     | Current revision number                          |

## Invariants and Constraints

- The first accepted score atomically transitions `Ready` to `Running`
- A stale or unauthorized transition changes nothing (optimistic concurrency via revision field)
- Publishing, synchronization, archiving, and visibility do not change execution lifecycle state
- A published contest is delisted before an approved deletion
- A published contest is not physically deleted by ordinary synchronization
- Admin lock prevents scoring configuration changes while locked
- Participant scoring access controls which participants can submit scores

## Lifecycle

State machine for `lifecycle_state`:

- Created → Configuring → Ready → Running → Completed
- Created: contest exists but no configuration begun
- Configuring: active configuration in progress
- Ready: configuration complete; awaiting first score
- Running: first score accepted; scoring active
- Completed: final scores accepted; closed for new participation

Completion closes participant scoring and prevents new participation or matrix changes; authorized score corrections remain possible as new revisions.

## Privacy and Scope

- Contest identity, schedule, and location are shared across authorized installations
- Participant data visibility is controlled by `visibility` (Private/Hidden/Public)
- Owner identification (`owner_account_id`) links to Account entity for ownership rules
- Anonymous contests have no `owner_account_id` and use anonymous verification flow

## Audit and Synchronization

- Every state transition records: actor, authority, source installation, base revision, resulting revision, server/client timestamps
- Configuration changes follow lifecycle mutability rules and create new revisions
- Sync cursor tracks installation-to-installation synchronization positions
- Sync operations validate revision numbers to prevent stale updates
