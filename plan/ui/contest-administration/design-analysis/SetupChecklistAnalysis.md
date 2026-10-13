# Setup Checklist — Implementation Analysis

Analysis of the "Setup checklist" section (Section 3) of the Claude AI design-tool export `Contest Workspace Canvas.dc.html`, mapped against the current Soar Score codebase to determine what can be implemented today, what is missing, and what the design still has to settle.

Source files examined:

- `Contest Workspace Canvas.dc.html` (the design canvas, variants 3a to 3c)
- `Contest Workspace.dc.html` (the live component with the checklist's data logic)
- `plan/ui/contest-administration/briefs/workspace.md` (the design brief)
- `plan/ui/contest-administration/contest-workspace.md` (the page requirement)
- `apps/soar_score_contest/lib/services/workspace/` and `lib/widgets/workspace/` (the workspace code already merged)
- GitHub issues #342 to #352 and #250 (workspace work and its siblings)

## What the design specifies

The **Setup checklist** is shown while the contest lifecycle is `Created`, `Configuring` or `Ready`, and is hidden once the contest is `Running` or `Completed` (from then on the same facts live in "Contest facts", and anything that goes wrong appears under "Needs attention").

It is a card with a header ("Setup checklist" plus a summary line, e.g. "3 of 4 required items done") and two lists. Each row is a button with an icon, a title, a one-line detail, a status label and a chevron; it navigates to the place where the item is fixed. Statuses never rely on colour alone: each has an icon and a text label (Done, To do, Missing, Check).

### Required items (4)

1. **Configuration saved and valid.** "To do" until a configuration is saved; then "Done" with the revision number and save time. Links to the Configuration page.
2. **Discipline and landing table.** "To do" until the configuration is saved; then "Done" with the discipline, landing table and house-rule count. Links to the Configuration page at the relevant section.
3. **At least 2 scoring pilots.** "Missing" when fewer than two; otherwise "Done" with the count and, when enabled, teams and classes. Links to the Participants page.
4. **Matrix drawn.** "To do" (with a note that it can be drawn once the items above are done, or that it is ready to draw), "Done" (revision, rounds, group sizes), or "Check" when the configuration has changed since the draw ("Matrix drawn with lanes off; lanes are now Random"). Links to the Matrix page.

### Optional items (3)

Clearly marked optional:

5. **Participant numbers assigned.** "To do" until the matrix is drawn, then "Done". Links to the Participants page.
6. **Publication.** "Not published" (publishing is possible before or after the contest) or "Published" with the visibility. Links to the publication control on the workspace.
7. **Participant scoring access.** "Closed" or "Open". Links to the scoring control on the workspace.

### The three variants

| Variant | Lifecycle frame                          | Required rows                                                      | Optional rows                                              |
| ------- | ---------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------- |
| 3a      | Configuring, matrix drawn, config drifts | Config done, discipline done, pilots done, **matrix "Check"**      | Numbers "To do" (see gap 3), not published, scoring closed |
| 3b      | Configuring, 1 pilot                     | Config done, discipline done, **pilots "Missing"**, matrix "To do" | Numbers "To do", not published, scoring closed             |
| 3c      | Ready                                    | All four done                                                      | Numbers done, not published, scoring closed                |

All three are buildable today. The "Created" case (nothing saved) appears only inside the full-page frame 1a, not in section 3.

## What already exists

The workspace scaffolding landed in #349 to #352 and the facts loader in #342. The checklist is the one section still on its placeholder.

- **Visibility by lifecycle.** `WorkspaceLayoutPlan.of` (`services/workspace/workspace_layout_plan.dart`) already places `WorkspaceSection.checklist` for `created`, `configuring` and `ready`, and omits it for `running` and `completed`. Nothing to build for gating.
- **Slot.** `WorkspaceSectionSlot` (`widgets/workspace/workspace_section_slot.dart`) renders a `WorkspacePlaceholderCard` ("Setup checklist goes here") until a widget is passed as `child`.
- **Facts.** `WorkspaceFacts` (`services/workspace/workspace_facts.dart`) is already loaded by the workspace page. It carries `contest`, `configuration` (a `ContestConfigurationRevision`), `options` (`CoreOptions`), `configurationProblem`, `scoringPilots`, `teamCount`, `matrix`, `roundCount`, `groupCount`, `groupSizeMin`, `groupSizeMax`, `configDrift`, `drawReadiness`, `publication` and `unavailable`.
- **Existing rules, not to be copied.** `DrawReadiness` decides whether a draw is possible; `ConfigDrift.differences` decides whether the matrix differs from the configuration (team protection, draw mode, lane mode, preliminary rounds); `ConfigurationProblem` decides whether the saved configuration is usable.
- **Publication.** `PublicationFacts` already decodes the untyped publication map defensively and distinguishes `notPublished` from `unknown`.
- **Focus targets.** The status-panel link and focus controller (#351, `widgets/workspace/workspace_focus_controller.dart`) give rows 6 and 7 a way to focus the publication and scoring controls.

## Data per row

| Row                                 | Source                                                                                    | Status                             |
| ----------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------- |
| Config saved and valid              | `facts.configuration` (`revisionNumber`, `createdAt`), `facts.configurationProblem`       | Available                          |
| Discipline                          | `SystemDisciplineProfiles` looked up by `configuration.disciplineProfileId`               | Available (bundled profiles)       |
| Landing table name                  | `ApiClient.landingTables()` matched to `configuration.landingTableId`                     | **Not in facts**                   |
| House-rule count                    | The configuration page's `SettingCatalog` / `ConfigurationValues` comparison to official  | **Not in facts**; reuse that logic |
| Scoring pilots, teams, classes      | `facts.scoringPilots`, `facts.teamCount`, `facts.options.teamsEnabled` / `classesEnabled` | Available                          |
| Matrix revision, rounds, groups     | `facts.matrix.revision`, `roundCount`, `groupCount`, `groupSizeMin`, `groupSizeMax`       | Available                          |
| Matrix differs from configuration   | `facts.configDrift`                                                                       | Available                          |
| Participant numbers (range)         | `ContestParticipation.participantNumber`; the facts do not keep the participations        | **Not in facts**                   |
| Publication                         | `facts.publication`                                                                       | Available (can be `unknown`)       |
| Scoring access                      | `facts.contest.scoringAccess`                                                             | Available                          |
| Self-scoring "off in configuration" | Dropped: there is no such option, and none will be added (#366)                           | Not shown                          |

No new endpoint, model or sync feature is needed. The additions are to `WorkspaceFacts` and its loader.

## Gaps the design must settle before implementation

1. **Saved but invalid configuration has no state.** The design treats row 1 as done once a configuration exists, but `configurationProblem` shows a saved configuration can be unusable. Add a Missing or Check state that shows the problem text.
2. **Publication `unknown` and offline.** The design only has Published and Not published. When the read fails or the endpoint is disabled (issue #363), the row must say it could not be read, not "Not published". The row also needs a decision for offline.
3. **Participant numbers in 3a.** The design shows "To do" when the matrix has drifted (`m && !changed`), but numbers are assigned at every draw (`MatrixDrawBuilder.numbered`), so a drifted matrix already has them. Show Done.
4. **Participant numbers when the option is off.** `participantNumbersEnabled` is an option, off by default. Decide whether the row is hidden, or shown as not applicable, when it is off.
5. **Self-scoring note.** Resolved by #366: there is no self-scoring setting; `scoringAccess` is the only switch. Drop "Self-scoring is off in the configuration". The Ready next step follows `scoringAccess` alone, as the shipped resolver (#343) does.
6. **Row 4 gating** should use `facts.drawReadiness`, not the design's `cfg.valid && pilots >= 2` shortcut.
7. **Deep-link anchors** ("Configuration at Discipline" and "at Landing table"): confirm the configuration page can open at a section, or settle for the page link.

## Outstanding tickets

- **Done and relied on:** #342 facts, #349 layout plan, #350 section slots, #351 status-panel focus links, #352 page states.
- **Open and adjacent:** #250 (contest controls: rows 6 and 7 focus those cards), #363 (publication endpoint disabled in the embedded server: row 6 will often be `unknown`).
- **Raised from this analysis:** #367 (the card), #365 (facts it needs) and #366 (decision on the self-scoring option, resolved: no setting).
- **Not needed:** #345 (audit trail) and #125 (publication page).

## What blocks the rest of the workspace (not the checklist)

| Workspace section            | What is missing                                                                             | Status                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------- |
| Next step card               | Nothing for the card; some targets still show "not available yet" dialogs                   | Merged (#342 to #344)                     |
| Progress / Needs attention   | Widgets; `scores()` and round facts are already in `WorkspaceFacts`; Scoring page not built | Widgets not built                         |
| Contest controls             | Control cards, confirmations and undo snackbars; `ContestActionRunner` exists               | #250 open                                 |
| Contest facts                | Widget only; the data is in `WorkspaceFacts`                                                | Widget not built                          |
| Recent activity              | Audit read API and page                                                                     | #345 open                                 |
| Offline / unavailable states | Full sync protocol for the offline variants                                                 | Banners merged (#352); sync is later work |

## Conclusion

The Setup checklist is **nearly ready to implement**. All three variants are possible with data the workspace already loads, plus four small additions to `WorkspaceFacts` (landing table name, house-rule count, participant-number range, and the saved-at time which is already on the revision). The layout plan and slot are in place.

Before building, settle gaps 1 to 4, 6 and 7 above in the design (they are small copy and state decisions, not new data). Gap 5 is settled: the self-scoring sentence is dropped.
