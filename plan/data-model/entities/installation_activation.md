# InstallationActivation

**Relationship to architecture-requirements:** plan/architecture-requirements/offline-synchronization.md (Administration Installation)  
**Purpose:** The record of which installation holds administrative authority over a contest, and for how long. A contest is administered from one active installation at a time. Activating a replacement ends the previous installation's authority, and the server then rejects that installation's later administrative changes as inactive-device mutations. It lives on the server so no device can edit it or create a conflict over who is in charge.  
**Identifier:** `id` (UUIDv7)  
**Parent entity:** Contest  
**Child entities:** None

## Relationships

- Belongs to a Contest (`contest_id`) and an Installation (`installation_id`)
- Activated by an Account (`activated_by`), the director's authenticated session

## Fields/Properties

| Field             | Type        | Required | Default | Description                                                                                                                  |
| ----------------- | ----------- | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `id`              | UUIDv7      | Yes      | -       | Primary key                                                                                                                  |
| `contest_id`      | UUIDv7      | Yes      | -       | FK Contest                                                                                                                   |
| `installation_id` | UUIDv7      | Yes      | -       | FK Installation that holds authority                                                                                         |
| `activated_by`    | UUIDv7      | Yes      | -       | FK Account of the director who activated it                                                                                  |
| `kind`            | enum        | Yes      | -       | `Initial` (first activation), `Replacement` (moved to another device), or `Reclaim` (the earlier device took authority back) |
| `activated_at`    | timestamptz | Yes      | -       | When authority was granted (server time)                                                                                     |
| `ended_at`        | timestamptz | No       | -       | When authority ended. Null while this is the active row                                                                      |
| `upload_open`     | boolean     | Yes      | false   | True while the contest's first upload is still being sent in several exchanges; closed when the client finishes it           |

## Invariants and Constraints

- At most one open row exists per contest: (`contest_id`) is unique where `ended_at` is null. This is the single-administrator rule of the first release
- Activating an installation ends the contest's open row and creates the new one in one transaction
- Activation requires an authenticated session of the contest's owning account while connected to the service. A revoked installation cannot be activated
- A change from an installation with no open row for the contest is rejected as an inactive-device mutation. The installation keeps read and export access
- `Reclaim` happens only after the earlier installation has pulled the changes committed since and reconciled any conflicts, then confirms "Reactivate as Primary and Sync"
- Unsynchronized changes that existed only on an unavailable installation cannot be recovered by the service
- Rows are never deleted

## Lifecycle

`ended_at` and `upload_open` are the columns that change after creation. `upload_open` is set only on the `Initial` row, by the exchange that creates the contest when it says the upload continues, and cleared when the client finishes the upload.

Created on activation, closed (`ended_at` set) when another installation is activated. A contest that has never been synchronized has no row; it is administered locally.

## Future: more than one administrator

The first release allows one open row per contest. Supporting several devices administering the same contest later would relax the unique constraint to one open row per contest and installation, and the server would test whether a mutation's installation has any open row instead of whether it is the only one. A role on the row, for example a primary that owns configuration and state transitions and secondaries that only score, could be added then as an optional column defaulting to the primary. The device on each mutation and the conflict handling already work for this. What would need deciding is behaviour: which device may finalize a matrix or complete the contest, and how conflicts between two directors' devices are shown.

## Privacy and Scope

- Backend only. Never synchronized to installations
- Visible to the contest's owner and to system administrators

## Audit and Synchronization

- Every activation and every end is recorded as an `InstallationActivation` AuditEvent with the actor, the installation, and the reason
- Not synced
