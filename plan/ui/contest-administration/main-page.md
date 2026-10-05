# RC Soar Score User Interface - Contest Selection

The user reaches this page after signing in or choosing offline mode. It is the director's contest-selection and system-management page.

The route that the application will come to after the user has logged in will be `/contest-administration/home`.

## Page actions

The page provides:

- A list of the ten most recently opened or created non-archived contests, ordered by most recent activity.
- `Show all contests` when more than ten eligible contests exist, loading the next 50 records per page.
- `Create contest`.
- `Open`, `Continue`, or `View` for the selected contest.
- `Delete` for the selected contest.
- `Request delisting` for a selected contest that has a published record.
- Navigation to previous participants, participant roles, and landing table management.
- `Sync` when the user is authenticated and a remote connection is available.

Archived contests are excluded by default and are available through an explicit archive filter. Deleted contests no longer exist and are not listed.

## Contest list

Each row shows contest name, date range, venue/location, last activity, and the independent status values defined in the [contest state presentation](./README.md#contest-state-presentation). Show an empty state with `Create contest` when there are no contests. Loading more retains the current selection only if that contest remains in the result set.

Selecting a row makes it the active selection and enables applicable actions. Double-clicking is equivalent to the primary open action but every action must also be available by keyboard.

## Opening a contest

The user may select one of the contests from the list and "open" it. The navigation button for this should indicate that the "opening" action is different based on the state of the contest.

States and button indication:

| States                     | Button indication | Navigation Result                                                   |
| -------------------------- | ----------------- | ------------------------------------------------------------------- |
| `Created` or `Configuring` | Open              | Contest configuration                                               |
| `Ready` or `Running`       | Continue          | Contest workspace, focused on the latest group with accepted scores |
| `Completed`                | View              | Contest reports or read-only contest workspace                      |

## Creating a New Contest

To create a new contest the contest director clicks on the button for creating a new contest. They are navigated to the wizard for creating the contest.

## Deleting a selected contest

`Delete` is enabled when a contest is selected. Any contest can be deleted after confirmation. The confirmation states that the director's working data for the contest, including pending mutations and local backup data, will be removed and cannot be recovered through the application.

When the contest has a published record, the confirmation must also say that the published record remains publicly available, loses its link to the contest, and can no longer be updated. Deleting a contest never removes a publication; removing it from public view requires a delist request.

## Requesting delisting

`Request delisting` is a separate action, available when the selected contest has a published record that is not already `Delisted`. It explains that a system administrator reviews the request and decides whether to remove the published record from public view, and it accepts an optional reason. The request is created with the state `pending`.

While a request is pending, the director can withdraw it. A pending request does not make the contest read-only: editing, scoring, and publishing continue as before. The row shows the request state (`pending`, `approved`, `denied`, or `withdrawn`), and an approved request shows the published record as `Delisted`.

If deletion or a delist request is rejected by the service, show the server reason and leave the contest unchanged. Do not use a generic success message for a queued or rejected request.

## System data management

The page provides navigation to the participant manager for the director's own participant records. The participant manager lists and edits records with the [participant editor](participant-data.md). It also searches the participant directory, where people offer their own details, and copies a directory entry into a new record that the director owns. When the participant hides their email, the copied record shows the email as "available to the system" instead of the address.

## Managing Participant Roles

The role manager lists the system roles (`Pilot`, `Helper`, and `Team Manager`) and the director's own non-flyer roles. A role is a label only: it grants no permissions, and an "Official" role is only a name. The director can add, rename, and archive their own non-flyer roles. Renaming affects only participants given the role afterwards, because each participant keeps the role name it had when assigned. Roles are archived rather than deleted; an archived role cannot be given to new participants but stays on existing ones. The `Pilot` role is immutable and cannot be changed or archived, and system roles cannot be deleted.

## Landing Tables

The landing-table manager lists the director's landing tables and the system tables. A table has a name, the unit of its key (meters, feet, or points), and a list of entries, each with a key, a label, and points. A table is immutable once created, so a change means creating a new table, for example by copying an existing one. A table is not tied to a discipline; the contest configuration selects the table a contest uses.
