# Setup Checklist — Implementation Analysis

Analysis of the "Setup checklist" section (Section 3) of the Claude AI design-tool export `Contest Workspace Canvas.dc.html`, mapped against the current Soar Score codebase to determine what can be implemented today and which outstanding work gates the full workspace page.

Source files examined:

- `Contest Workspace Canvas.dc.html` (the design canvas)
- `support.js` (the DC design-tool runtime that renders the canvas)
- `Contest Workspace.dc.html` (the live component with the checklist's data logic)
- `plan/ui/contest-administration/briefs/workspace.md` (the design brief)
- `plan/ui/contest-administration/contest-workspace.md` (the page requirement)
- `plan/tickets/mvp-implementation/` (ticket index and status)

## What the design specifies

The **Setup checklist** is shown while the contest lifecycle is `Created`, `Configuring` or `Ready`, and is hidden once the contest is `Running` or `Completed` (from then on the same facts live in "Contest facts", and anything that goes wrong appears under "Needs attention").

It is a card with a header ("Setup checklist" plus a summary line, e.g. "3 of 4 required items done") and two lists.

### Required items (4)

1. **Configuration saved and valid.** "To do" until a configuration has been saved; once saved, "Done" with the revision number and save time. Links to the Configuration page.
2. **Discipline and landing table.** "To do" until the configuration is saved; "Done" with the discipline, landing table, and house-rule count. Links to the Configuration page at the relevant section.
3. **At least 2 scoring pilots.** "Missing" (error style) when fewer than two pilots; otherwise "Done" with the count and, when enabled, team/class information. Links to the Participants page.
4. **Matrix drawn.** Three states:
   - "To do" — not drawn yet, with a note that it can be drawn once the items above are done (or that it is ready to draw).
   - "Done" — drawn, with revision, round count, and group sizes.
   - "Check" (warning) — the configuration has changed since the draw ("Matrix drawn with lanes off; lanes are now Random"). Links to the Matrix page.

### Optional items (3)

Clearly marked "Optional":

5. **Participant numbers assigned.** "To do" until the matrix is drawn (numbers are assigned automatically at draw time); "Done" afterwards. Links to the Participants page.
6. **Publication.** "Not published" (with a note that publishing can happen before or after the contest) or "Published" with the visibility. Links to the publication control on the workspace.
7. **Participant scoring access.** "Closed" (with a note that it can be opened when pilots should enter their own scores, or that self-scoring is off in the configuration) or "Open". Links to the scoring control on the workspace.

Each row is a button with an icon, a title, a one-line detail, a status label, and a chevron; it navigates to the page where the item can be fixed. Statuses never rely on colour alone: each has both an icon and a text label.

## Data required, and where it comes from

All data for the checklist is already reachable through the existing `ApiClient` (`packages/soar_score_api/lib/client/api_client.dart`). No new endpoint, model, or sync feature is needed.

| Checklist item                          | `ApiClient` method                                      | Type returned                    |
| --------------------------------------- | ------------------------------------------------------- | -------------------------------- |
| Configuration saved and valid           | `configuration(Id)`                                     | `ContestConfigurationRevision`   |
| Discipline and landing table            | `configuration(Id)`                                     | `ContestConfigurationRevision`   |
| At least 2 scoring pilots               | `participations(Id)`                                    | `List<ContestParticipation>`     |
| Matrix drawn (revision, rounds, groups) | `matrix(Id)`                                            | `CurrentMatrix`                  |
| Matrix-vs-configuration drift           | `matrix(Id)` + `configuration(Id)` compared client-side | both of the above                |
| Participant numbers assigned            | `matrix(Id)`                                            | `CurrentMatrix`                  |
| Publication status                      | `publication(Id)`                                       | `Map<String, Object?>` (untyped) |
| Scoring access, lifecycle, lock         | `contest(Id)`                                           | `Contest`                        |

Existing types that already carry the needed values:

- `Contest` (`packages/soar_score_core/lib/models/contest/contest.dart`) — `lifecycleState`, `scoringAccess`, `adminLock`, `resultsHiddenThroughRound`, `localArchive`.
- `ContestConfigurationRevision` — discipline, landing table reference, revision, validity.
- `CurrentMatrix` — revision, rounds, groups, draw settings, assignments.
- `ContestParticipation` — pilot role (scoring vs. not).

The "matrix doesn't match configuration" warning is pure client-side comparison between the draw settings stored in the `CurrentMatrix` and the current `ContestConfigurationRevision`; both objects are already in hand.

## What can be implemented now

The Setup checklist is **fully implementable today**. Everything it needs already exists:

- The route `/contest-administration/contests/:id/workspace` and the `ContestWorkspacePage` (`apps/soar_score_contest/lib/pages/contest_workspace_page.dart`).
- The app shell, navigation rail, and status panel the page lives in.
- All domain models and the `ApiClient` methods listed above.
- The theme tokens the design's rationale section relies on (primary `#006399`, success/warning container colours, elevation 1/2).

What remains is implementation work only, in the contest app:

1. A `SetupChecklist` widget that loads `configuration()`, `participations()`, and `matrix()` in parallel.
2. Status computation for each of the seven items (Done / To do / Missing / Check).
3. Lifecycle gating: render the checklist for `Created`, `Configuring` and `Ready`; hide it for `Running` and `Completed`.
4. Navigation targets per item (Configuration, Participants, Matrix pages — all routes already exist).

Two small gaps to close in the same work:

- **Publication status** — `client.publication(id)` currently returns an untyped `Map<String, Object?>`; a typed view (or a small decode) is needed to read the published/unpublished and visibility values cleanly.
- **Self-scoring setting** — the checklist's scoring note ("self-scoring is off in the configuration") needs the configuration's participant-scoring option, which is part of the saved configuration and already returned by `configuration(id)`.

## What blocks the rest of the workspace (not the checklist)

The other sections of the designed workspace have heavier dependencies. None of them gate the checklist itself.

| Workspace section                                                                     | What is missing                                                                                                                    | Status                                            |
| ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| Next step card                                                                        | Combined lifecycle + matrix + scores + publication logic to pick the action                                                        | Not built; part of the workspace UI work          |
| Progress / Needs attention                                                            | `scores()` and `roundResults()` data and a Scoring page to link to                                                                 | Scoring page not built (later milestone)          |
| Contest controls (lock, complete, open/close scoring, hide results, publish, archive) | `applyContestAction()` and `publishContest()` exist in the API client; the dialogs, confirmations and undo snackbars are not built | API ready; UI not built                           |
| Contest facts (beyond dates and location)                                             | Matrix revision, pilot counts, configuration revision — all available via the API, not yet rendered                                | UI only                                           |
| Recent activity                                                                       | Audit event repository/service exist in core; no API endpoint or page yet                                                          | Later milestone                                   |
| Offline / unavailable / load-failed states                                            | Full sync protocol (ticket 037, GitHub issues #83–#92)                                                                             | Affects only the offline and unavailable variants |
| Scoring, Reports, Publication pages                                                   | Target pages for the checklist links and next-step buttons                                                                         | Later milestones                                  |

## Outstanding tickets relevant to this work

From `plan/tickets/mvp-implementation/README.md` (work is now tracked in GitHub issues; these files are the historical record):

- Data models (035) — **Done**; Drift schema (036) and sync engine (037) — **Tracked in GitHub issues**.
- Contest home and workspace plumbing (027–033) — routes, shell, list, selection, sync stub are in place; the sync action (033) is a stub until the sync protocol lands.
- Nothing in the ticket index is a dedicated blocker for the Setup checklist. Implementing it is a straightforward new work item in the contest app, and would normally be raised as a GitHub issue under the workspace milestone rather than added as a ticket file.

## Conclusion

Section 3 of the design — the Setup checklist — is **ready to implement**. Every data dependency is satisfied by the current API client and domain models, the page and its route exist, and no outstanding ticket gates it. The work is purely additive UI: one widget, seven status computations, lifecycle gating, and navigation. The only adjacent decisions to make are how to decode the publication status cleanly and where the checklist's optional items link (to their workspace controls versus their pages).
