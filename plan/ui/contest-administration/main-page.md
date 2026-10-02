# RC Soar Score User Interface - Contest Selection

The user reaches this page after signing in or choosing offline mode. It is the director's contest-selection and system-management page.

The route that the application will come to after the user has logged in will be `/contest-administration/home`.

## Page actions

The page provides:

- A list of the ten most recently opened or created non-archived contests, ordered by most recent activity.
- `Show all contests` when more than ten eligible contests exist, loading the next 50 records per page.
- `Create contest`.
- `Open`, `Continue`, or `View` for the selected contest.
- `Delete` for an unpublished local contest, or `Request delisting` for a contest published at least once.
- Navigation to previous participants, participant roles, and landing bonus management.
- `Sync` when the user is authenticated and a remote connection is available.

Archived contests are excluded by default and are available through an explicit archive filter. Deleted contests are not listed.

## Contest list

Each row shows contest name, date range, venue/location, last activity, and the independent status values defined in [overview.md](./overview.md). Show an empty state with `Create contest` when there are no contests. Loading more retains the current selection only if that contest remains in the result set.

Selecting a row makes it the active selection and enables applicable actions. Double-clicking is equivalent to the primary open action but every action must also be available by keyboard.

## Opening a contest

The user may select one of the contests from the list and "open" it. The navigation button for this should indicate that the "opening" action is different based on the state of the contest.

States and button indication:

| States                     | Button indication | Navigation Result                                                   |
| -------------------------- | ----------------- | ------------------------------------------------------------------- |
| `Created` or `Configuring` | Open              | Contest configuration                                               |
| `Ready` or `Running`       | Continue          | Contest workspace, focused on the latest group with accepted scores |
| `Completed`                | View              | Contest reports or read-only contest workspace                      |

`PendingDelete` opens a read-only deletion-status view. `Deleted` contests cannot be opened.

## Creating a New Contest

To create a new contest the contest director clicks on the button for creating a new contest. They are navigated to the wizard for creating the contest.

## Deleting or delisting a selected contest

A delete action is enabled only when a contest is selected and the deletion rules allow it. An unpublished local contest can be deleted after confirmation. The confirmation states that local data, pending mutations, and backup data associated with the contest will be removed and cannot be recovered through the application.

For a contest published at least once, the action is `Request delisting`. It explains that delisting removes the public projection from public viewing but starts a pending-delete workflow; it does not immediately erase the private contest or publication history. The request requires explicit confirmation and shows `PendingDelete` when accepted. Pending deletion blocks ordinary editing, scoring, and publishing.

If deletion is rejected by the service, show the server reason and leave the contest unchanged. Do not use a generic success message for a queued or rejected request.

## System data management

The page provides navigation to the participant editor for the director's reusable local participant records.

## Managing Participant Roles

The role manager lists the default immutable `Pilot` role and director-owned non-flyer roles. It must prevent deletion or modification of the default role.

## Landing Bonuses

The landing-bonus manager supports director-owned named key/points tables used by discipline configuration.
