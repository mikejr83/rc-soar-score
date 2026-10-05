# RC Soar Score User Interface

The documents in this folder define the contest director's administration experience, including contest selection, configuration, matrix management, scoring, offline operation, and reporting.

## Documents

- [`contest-workspace.md`](contest-workspace.md) - Contest configuration, matrix, and state actions.
- [`landing-page.md`](landing-page.md) - Landing page requirements.
- [`main-page.md`](main-page.md) - Contest selection and system-management page requirements.
- [`matrix.md`](matrix.md) - Flight matrix inspection and redraw interactions.
- [`new-contest-wizard.md`](new-contest-wizard.md) - New contest and initial configuration workflow.
- [`official-scoring.md`](official-scoring.md) - Director and local-operator score entry.
- [`offline-ui.md`](offline-ui.md) - Offline application-frame, connectivity, and synchronization UI.
- [`participant-data.md`](participant-data.md) - Director-owned participant editing requirements.
- [`reports.md`](reports.md) - Contest standings, result, and export views.

## Technology and visual rules

The application should be built to Material 3 standards.

<!-- The applications use Flutter and Material 3. Use Material 3 components and theme tokens before adding custom styles. Any custom values must be defined as theme tokens at the application root so the theme can be adjusted centrally. -->

Administrative screens target tablet and larger screens. They must remain usable with browser text zoom and larger configured fonts; dense tables must provide a responsive alternative such as horizontal scrolling or a stacked row view. Participant self-scoring is mobile-first and must use large, high-contrast controls suitable for outdoor use. Do not communicate state by color alone. Every status has text, an icon or shape, and an accessible label.

## Navigation and route contract

The application uses a persistent shell with:

- A title and current contest name when a contest is selected.
- Breadcrumbs or an equivalent back-navigation control showing the current location.
- A main navigation area for contest administration tasks.
- A content area with one clear primary action per workflow step.
- A status area at the bottom of the shell.

Browser back navigation must preserve the current contest and relevant round/group selection. Destructive or multi-step actions use a confirmation dialog; ordinary navigation does not use a modal.

The UI must handle loading, empty, unavailable, validation-error, authorization-error, conflict, and save-failed states. A failed save keeps the user's entered values and provides retry and cancel actions. Unsaved wizard changes must produce a leave-page warning.

## Contest state presentation

Execution lifecycle, participant scoring access, administration lock, results hiding, publication, public visibility, and local archive are separate values. The UI must never combine them into one status field or infer one from another. A contest has no deletion status: deleting a contest removes it, and removing a published record from public view is a separate delist request (see [contest-state-and-transitions.md](../../architecture-requirements/contest-state-and-transitions.md)).

When a contest is selected, show a compact status summary with labeled values for:

- Lifecycle: `Created`, `Configuring`, `Ready`, `Running`, or `Completed`.
- Participant scoring: `Open` or `Closed`.
- Administration: `Unlocked` or `Locked`.
- Results hiding: `Off`, or hidden through round N.
- Publication: `Unpublished` or `Published`.
- Public visibility when published: `Unlisted` or `Public`. A published record removed by an administrator shows `Delisted`.
- Local archive: shown when the contest is archived on this installation.

Only controls allowed by the current state and the current user's authority are enabled. Disabled controls must have an adjacent explanation or an accessible disabled-state description. `Completed` closes participant scoring but permits authorized score correction workflows.

## Application status area

The status area is persistent on the offline shell and available in the online application when relevant. It shows:

- Internet connectivity.
- Remote API connectivity and the time of the last successful connection.
- Synchronization state: last successful sync, unsent mutation count, remote revision, and conflicts requiring action.
- The selected contest's lifecycle and participant-scoring state.
- Latest round with accepted scores, latest group with accepted scores, pilots missing scores, and open score-review requests.

Selecting a status item opens the relevant details or action. Status is not a substitute for an error message: rejected mutations and conflicts must remain inspectable with the reason and available resolution.

## Accessibility and responsive behavior

All controls have labels, keyboard access, visible focus, and screen-reader state announcements. Tables expose column headers and row context. Dates, times, decimal separators, and number formatting follow the user's locale while stored values retain their domain meaning. Touch targets must be large enough for mobile use. Administrative grids may scroll horizontally; participant forms must not require horizontal scrolling.
