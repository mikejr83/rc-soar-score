# Contest

**Relationship to architecture-requirements:** plan/architecture-requirements/data/contest.md  
**Purpose:** The private source-of-truth aggregate for one radio-controlled soaring event. Stores identity, location, schedule, configuration state, and all derived scoring state.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** None (top-level aggregate)  
**Child entities:** ConfigurationRevisions (1:N), MatrixRevisions (1:N), Participants/ParticipationLinks (1:N), ScorePlaceholders (1:N), AuditEvents (1:N); has SyncCursors; may have one PublicationIdentity (the link is optional on the publication side)

## Relationships

- Optional Account owner (0:1 from Contest.owner_account_id to Account.id)
- One SyncCursor per installation and contest
- Zero or one PublicationIdentity per contest. The publication outlives the contest: its `contest_id` is cleared when the contest is deleted
- Multiple ConfigurationRevisions (1:N), MatrixRevisions (1:N)
- Multiple Participants/ParticipationLinks, ScorePlaceholders, AuditEvents (1:N)

## Fields/Properties

| Field                          | Type     | Required | Default               | Description                                                                                                                                                                                   |
| ------------------------------ | -------- | -------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`                           | UUIDv7   | Yes      | Generated on creation | Primary key; stable event identifier                                                                                                                                                          |
| `name`                         | String   | Yes      | None                  | Contest name                                                                                                                                                                                  |
| `start_date_time`              | DateTime | Yes      | None                  | Start date/time in contest's timezone                                                                                                                                                         |
| `end_date_time`                | DateTime | Yes      | None                  | End date/time in contest's timezone                                                                                                                                                           |
| `timezone`                     | String   | Yes      | None                  | IANA timezone name; stored at creation                                                                                                                                                        |
| `host`                         | String   | No       | None                  | Host/venue name                                                                                                                                                                               |
| `city`                         | String   | No       | None                  | City name                                                                                                                                                                                     |
| `state`                        | String   | No       | None                  | State/province name                                                                                                                                                                           |
| `country`                      | String   | No       | None                  | Country name                                                                                                                                                                                  |
| `owner_account_id`             | UUIDv7   | No       | None                  | FK to Account; null for anonymous/local contests                                                                                                                                              |
| `lifecycle_state`              | Enum     | Yes      | Created               | Created, Configuring, Ready, Running, Completed                                                                                                                                               |
| `scoring_access`               | Enum     | Yes      | Closed                | Closed, Open                                                                                                                                                                                  |
| `admin_lock`                   | Enum     | Yes      | Unlocked              | Unlocked, Locked                                                                                                                                                                              |
| `results_hidden_through_round` | Integer  | No       | None                  | Null when results are not hidden. Otherwise the round through which overall scores and placing are shown; set to the round in progress, or the last completed round, when hiding is turned on |
| `results_hidden_at`            | DateTime | No       | None                  | When hiding was turned on. Non-null exactly when `results_hidden_through_round` is non-null. Hiding expires 24 hours after this time                                                          |
| `local_archive`                | Boolean  | Yes      | false                 | Local archive flag. Local to the installation and never synchronized                                                                                                                          |
| `created_at`                   | DateTime | Yes      | now                   | When the contest was created (UTC)                                                                                                                                                            |
| `updated_at`                   | DateTime | Yes      | now                   | When the contest was last modified (UTC)                                                                                                                                                      |
| `revision`                     | Integer  | Yes      | 1                     | Current revision number                                                                                                                                                                       |

## Invariants and Constraints

- The first accepted score atomically transitions `Ready` to `Running`
- A stale or unauthorized transition changes nothing (optimistic concurrency via revision field)
- Publishing, synchronization, archiving, visibility, and results hiding do not change execution lifecycle state
- Deleting a contest removes the director's working data. A published record is not affected apart from losing its link to the contest
- Hiding ends when the director turns it off, when the contest becomes `Completed`, or 24 hours after `results_hidden_at`; ending it clears both hiding columns
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
- Publication state and visibility (`Unlisted`/`Public`/`Delisted`) belong to the PublicationIdentity, not the contest. A contest with no publication is visible only to its director
- While results are hidden, participant result views and the published copy show overall scores and placing only through `results_hidden_through_round`; round scores and flight-group positions stay visible
- Owner identification (`owner_account_id`) links to Account entity for ownership rules
- Anonymous contests have no `owner_account_id` and use anonymous verification flow

## Audit and Synchronization

- Every state transition records: actor, authority, source installation, base revision, resulting revision, server/client timestamps
- Configuration changes follow lifecycle mutability rules and create new revisions
- Sync cursor tracks installation-to-installation synchronization positions
- Sync operations validate revision numbers to prevent stale updates
