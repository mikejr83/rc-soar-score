# Agent Guide for Soar Score

This document is the primary source of truth for the Soar Score codebase. It is supplemented by per-project `AGENTS.md` files located in each `apps/` and `packages/` directory (e.g., `apps/soar_score_server/AGENTS.md`, `packages/soar_score_core/AGENTS.md`). When a convention in this root file conflicts with a per-project file, **this root file wins**.

Per-project files should be read for:

- Package-specific boundary constraints (what must NOT be imported or depended on)
- Folder layout and naming conventions unique to that subproject
- Targeted test and build commands

Per-project files should NOT override:

- Shared code style or linting rules (use root `analysis_options.yaml`)
- Business requirement references (always consult `./plan`)
- Version or toolchain pins (see root CI section)

## Project Overview

Soar Score is an RC sailplane soaring contest scoring and management suite. It consists of multiple Flutter and Dart applications and shared packages, all managed by Melos in a Dart monorepo, plus the public web site, a Next.js app in `apps/soar_score_web` (ADR 0005).

**Tech Stack:**

- Flutter
- Dart
- Melos
- Node.js 24 and npm (public site only)

## Environment Setup

**Prerequisites:**

- Melos
- Flutter (includes Dart)

## Testing Conventions

- Tests are located in `test/` directories within each app and package
- Flutter apps use `flutter_test` package
- Dart CLI/API projects use `test` package
- Run with: `melos test` or directly with `dart test` / `flutter test`
- End-to-end (E2E) tests for the contest app live in
  `apps/soar_score_contest/integration_test/` and run only locally with
  `scripts/e2e-contest.ps1` (or `scripts/e2e-contest.sh`; `-d web` / `-Device web` runs them in headless Chrome against a token-free test server, see `apps/soar_score_contest/AGENTS.md`). CI never runs them: `melos test`
  runs `test/` only. See `apps/soar_score_contest/AGENTS.md`.
- **Keep the E2E tests current.** After any change to the contest app's pages,
  routes, widget keys, visible labels, flows or demo data, run
  `scripts/e2e-contest.ps1` (or `scripts/e2e-contest.sh -d web`) and fix or extend the
  journeys the change affects, in the same PR. The contest lifecycle journey
  (`contest_lifecycle_journey_test.dart`, phases in
  `apps/soar_score_contest/integration_test/journey/`) covers a contest from
  start to results: a UI change extends the matching phase file with a step.
  Only a feature outside the lifecycle gets its own standalone `*_test.dart`,
  and the PR says why in one line. The allowed standalone files are listed in
  `apps/soar_score_contest/AGENTS.md`.
- The self-scoring app has its own E2E journey, in
  `apps/soar_score_self_score/integration_test/`, run with
  `scripts/e2e-score.sh` (or `scripts/e2e-score.ps1`); same rule: a change to
  its pages, flows or widget labels extends the matching phase in the same PR.
  See `apps/soar_score_self_score/AGENTS.md`.

## Code Style & Linting

- All projects use `analysis_options.yaml` at their root
- Flutter apps include `package:flutter_lints/flutter.yaml`
- Dart CLI projects include `package:lints/recommended.yaml`
- Run `melos analyze` to check

## CI/CD

- GitHub Actions workflow in `.github/workflows/ci.yml` (owned by ticket 011)
- Runs on push/PR to `master`
- The public site (`apps/soar_score_web`, Next.js) has its own `public-site` job: `npm ci`, lint, test, build. Melos does not manage it.
- Documentation-only changes skip the workflow entirely (`paths-ignore` covers `plan/**`, `docs/**`, `**/*.md`, `LICENSE`, `.prettierrc`, `.prettierignore`, `.gitignore`, `.mcp.json`, `.agents/**`, `.kilo/**`, `.vscode/**`, `.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/**`). A docs-only PR showing no checks is expected, not a CI problem.
- Steps: install deps → analyze → test → build

**Toolchain pins** (recorded in `plan/tickets/mvp-implementation/001-setup-toolchain-baseline.md`, which is the source of truth — CI must not drift from it):

- Flutter 3.47.x (stable channel)
- Dart: bundled with Flutter (3.13.x current, no independent pin)
- Melos 8.x

## Important Conventions

1. **Path dependencies**: All shared packages use path-based dependencies in `pubspec.yaml`
2. **JSON serialization**: Use `json_annotation` and `json_serializable` for data models
3. **State management**: Follow Flutter best practices for the specific app
4. **API design**: RESTful endpoints on shelf-based server

## Commit Messages

All commit messages follow the [Conventional Commits](https://www.conventionalcommits.org) specification:

```
<type>(<optional scope>): <short summary>

[optional body: explain what and why]

[optional footer(s): BREAKING CHANGE: ..., Closes #123]
```

- **Type** is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- **Scope** is optional. In this monorepo, use the affected app or package directory name, for example `feat(contest-app):`, `fix(server):`, `refactor(soar_score_core):`.
- **Summary** uses the imperative mood in present tense (`add`, `fix`, `remove` — not `added`, `adds`, `adding`), stays under 72 characters, and has no trailing period.
- **Body** (optional) explains what and why, not how.
- **Footers** (optional) reference issues (`Closes #123`, `Ref: #456`) and breaking changes:

  ```
  feat(server): change publication payload format

  BREAKING CHANGE: `score` fields are now `scorePoints`
  ```

## Formatting

### Markdown

- All Markdown files must conform to the repo's Prettier config (`.prettierrc`). Do not hand-format against it.
- After creating or editing any `.md` file, run `npx prettier --write <file>` and keep the result.
- Before finishing a task, run `npx prettier --check "**/*.md"` and fix any failures.
- Never disable or edit Prettier config or `.prettierignore` to make a check pass.
- Use `-` for bullets, `1.` style for ordered lists, and `_emphasis_` / `**strong**`.
- One blank line between blocks; no trailing whitespace; file ends with a single newline.
- Tables must be column-aligned (Prettier will realign them; just run it).
- Do not hard-wrap prose unless `proseWrap` is set in the config.

## Work Tracking

Planned work is tracked in GitHub issues (milestones M0 to M5, epic parent issues with sub-issues, `area:`, `type:`, `priority:` and `size:` labels). Do not add ticket files under `plan/tickets/`; those are historical. `./plan` remains the source of truth for requirements. See `CONTRIBUTING.md`.

## Business and Architecture Requirements

Documentation is provided in the `./plan` folder. This contains business, architecture, and ui requirements. Consult this documentation when determining the best course of action for implementing business logic.

## Page Map

When someone refers to a page by name, use this table. Paths below are all in `apps/`; routes are defined in each app's `lib/router.dart` (go_router), and the contest app's route constants and path helpers live at the top of that file.

### Contest app (`soar_score_contest`)

The landing page has no app shell. Every other page sits in the shell (`lib/widgets/contest_shell.dart`), whose rail (`shell_rail.dart`) shows one of two destination sets chosen in `shell_destinations.dart`: system scope (outside a selected contest) and contest scope (any route below `/contest-administration/contests/:contestId`, except the wizard).

| Name people use                                                      | Route                                                  | Source (`lib/`)                                                         |
| -------------------------------------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------------- |
| Landing page (sign in / "Continue offline"), no shell                | `/contest-administration`                              | `pages/landing_page.dart`                                               |
| Main page, contests page, contest list ("Contests" rail entry)       | `/contest-administration/home`                         | `pages/home_page.dart`, `widgets/contest_list.dart`                     |
| New contest wizard (rail "Create contest" button)                    | `/contest-administration/contests/new`                 | `pages/new_contest_wizard_page.dart`, `widgets/new_contest/`            |
| Workspace (contest scope, "Workspace" rail entry)                    | `/contest-administration/contests/:id/workspace`       | `pages/contest_workspace_page.dart`                                     |
| Contest configuration page ("Configuration" rail entry)              | `/contest-administration/contests/:id/configuration`   | `pages/contest_configuration_page.dart`, `widgets/configuration/`       |
| Matrix page, draw ("Matrix" rail entry)                              | `/contest-administration/contests/:id/matrix`          | `pages/matrix_page.dart`, `widgets/matrix/`                             |
| Contest participants page (contest scope, "Participants" rail entry) | `/contest-administration/contests/:id/participants`    | `pages/contest/participants_page.dart`, `widgets/contest_participants/` |
| Contest scoring page (contest scope, "Scoring" rail entry)           | `/contest-administration/contests/:id/scoring`         | `pages/contest/scoring_page.dart`, `widgets/scoring/`                   |
| Contest reports page (contest scope, "Reports" rail entry)           | `/contest-administration/contests/:id/reports`         | `pages/contest/reports_page.dart`                                       |
| Report viewer (outside the shell; opens from a report card)          | `/contest-administration/contests/:id/reports/:report` | `pages/contest/report_viewer_page.dart`, `widgets/reports/viewer/`      |
| Contest sync page (contest scope, "Sync" rail entry, native only)    | `/contest-administration/contests/:id/sync`            | `pages/contest/sync_page.dart`, `widgets/sync/`                         |
| Participants manager ("Participants" rail entry)                     | `/contest-administration/participants`                 | `pages/participants_page.dart`                                          |
| Participant editor (new / edit)                                      | `/contest-administration/participants/new`, `/:id`     | `pages/participant_editor_page.dart`, `widgets/participant_editor/`     |
| Role manager ("Roles" rail entry)                                    | `/contest-administration/roles`                        | `pages/roles_page.dart`, `widgets/roles/`                               |
| Landings manager ("Landings" rail entry)                             | `/contest-administration/landings`                     | `pages/landings_page.dart`, `widgets/landings/`                         |
| Settings page (account control at the bottom of the rail)            | `/contest-administration/settings`                     | `pages/settings_page.dart`, `widgets/settings/`                         |
| Landing table editor (new / copy)                                    | `/contest-administration/landings/new`                 | `pages/landing_editor_page.dart`                                        |
| Startup failure page (not a route)                                   | none                                                   | `pages/bootstrap_failure_page.dart`                                     |

Notes:

- Settings opens from the account control and keeps the current scope: `/contest-administration/settings` outside a contest, `/contest-administration/contests/:id/settings` (`contestSettingsPath`) inside one, so the contest rail stays.
- "Configuration page" always means the contest-scoped page above, not the draft step inside the wizard.
- The contest-scoped "Reports" page lists the four reports (`widgets/reports/`, state in `services/reports/`): a context strip (lifecycle, scoring progress, result status with its help popover), then a card per report under Results and Documents to print. A report that cannot be produced shows a disabled Open with its reason and a link; warnings (preliminary scores, configuration drift, undrawn seeded rounds) sit on the card. Open launches the viewer through `ReportLauncher` (`services/reports/`): its own browser tab on the web (with a blocked-pop-up fallback, Open here), in place with Back to Reports on native. The viewer (`ReportViewerPage`) is a reusable frame: filters, options and page setup live in the URL query, the sheet is an unthemed paper page, and each report supplies a `ReportDefinition` (controls and pages). A report that reads data of its own overrides `dataKey` and `loadData` on `ReportSpec`; the viewer reads the data again only when the key changes. Overall Standings (`widgets/reports/standings/`, rules in `services/reports/standings/`) is built: it shows the stored standing as of the last round shown, read from `GET /contests/{id}/results?asOfRound=N`, and never recalculates. A report with data of its own extends `DataReportDefinition<D>` (`widgets/reports/viewer/report_definition.dart`): `loadData` answers a `ReportLoad<D>` (`ReportLoaded`, `ReportNoData` or `ReportNothingToLoad`) and `buildWith` receives a typed `D`, so a report never casts the viewer's data. Draw Matrix (printed title "Flight Matrix"; `widgets/reports/draw_matrix/`, rules in `services/reports/draw_matrix/`) is built: it reads the matrix once (`DrawMatrixData`, keyed by matrix revision) and applies the round range (`from`, `to`), Compact mode (`cmp`) and Additional pilot info (`inf`, `club`, `fai`, `nat`; off in compact mode, the choice kept) to it without another read; `DrawMatrixLayout` paginates it (a group is never split when it fits, a round header always sits with its first group, a continued round or group repeats its header); every column but the pilot's shrinks to its content and every cell is measured, so a wrapping cell makes its row taller in the plan instead of running off the page, and a crowded sheet sets `ReportDocument.notice`, a screen-only banner that names the columns to turn off (Team, Pilot number, Pilot class and the extra info are switchable). Pilot Scoring Cards (`widgets/reports/pilot_cards/`, rules in `services/reports/pilot_cards/`) is built: one landscape card per pilot, four or two to a Letter/A4 page, cut apart after printing. It reads the matrix, the scores and the invitations once (`PilotCardsData`, keyed by matrix revision and scores signature) and applies the round range (`from`, `to`), Include retired pilots (`ret`), the pilot choice (`pilots`: ids, `none` or `all`), Pre-fill (`pre`; off until a score exists, values that are not official print with an asterisk) Cards per page (`up`: `auto`, `four`, `two`) and the print margin (`mg`: `std`, a quarter inch, or `wide`, 10 mm) to it without another read. `CardSheetDecision` decides four-up or two-up from the rounds, not a fixed count (every card sized as if it had a QR code, so sending invitations later never changes the page count); `CardSizing` holds the millimetre rules (rows of 8 to 10 mm, QR 25 mm shrinking to a 22 mm floor, the footer text sits in the top block beside the QR code, and 8 rounds fit four to a page on Letter and A4 while 9 go two, 2 mm inset at cut lines). The columns follow the discipline (`CardColumns`). The report sets `fixedOrientation` (no Orientation control), `hasRunningFrame: false` and `barePageMargins(filters, facts)` (the print margin on every side, because printers cut the shared sheet's 4 mm sides and bottom) on `ReportSpec` because each card carries its own header and footer; it adds `ReportDocument.banners` and `beforePrint` (a reminder shown before the system print dialog) and `ReportSpec.changesOf` so the viewer redraws when an invitation is sent. A card shows a QR code (`qr` package, version 5 or larger for a longer link, error correction M, four modules of white on every side; a create that worked but could not be read back shows "QR codes were created" with Load QR codes, never a failed create) only when its pilot has an invitation; invitations are read and issued through `PilotInvitationSource` (`PilotInvitationSources.current`, default `ApiPilotInvitationSource`: `GET`/`POST /contests/{id}/invitations` on the hosted server, so `ReportDataRequest.publicationClient`, the same client publishing uses). Issuing never emails, and the dialog and banners say so. A contest the hosted server does not have reads as not synchronized, no sign-in or a server that issues none as send unavailable with the reason beside the action, and a failed read leaves the cards printable with a retry banner (`InvitationPhase.loadFailed`). Invitations are also sent from the workspace (`InvitationsSection`, `WorkspaceSection.invitations`, directly under the setup checklist, and under the next-step card while Running) and from the Participants list (an Invitations menu beside Remove: Send invitations for the selected pilots without one, Copy link for exactly one pilot who has one). All three use `PilotInvitationSession` and the same confirmation (`sendInvitationsWithConfirmation`, `widgets/invitations/`); resend, regenerate and helper links are #791. `UnavailablePilotInvitationSource` leaves cards without a code for tests; the lifecycle journey (phase 4) swaps in `StubPilotInvitationSource` (`integration_test/support/`) because its embedded server has no invitations. Scoring Sheet (`widgets/reports/scoring_sheet/`, rules in `services/reports/scoring_sheet/`, #479) is built: the draw by round and group with blank, ruled cells for officials to write scores in by hand (9 mm rows, real 5 mm tick boxes, black rules only). It reads the matrix and scores once (`ScoringSheetData`, keyed by matrix revision and scores signature) and applies the round range (`from`, `to`), Club (`club`, off), Team, Pilot number and Pilot class (`team`, `num`, `cls`, each only when the contest uses it), Validated (`val`, on), Include retired pilots (`ret`) and Pre-fill (`pre`) without another read. The columns come from the discipline (`ScoringSheetColumns`, reusing the `CardColumns` height and restart rules): Lane when the draw has lanes, the pilot, the optional identity columns, then the score components, Penalty, Reflight and Validated. Writing cells get spare width first, then the pilot's name up to 70 mm. `ScoringSheetLayout` never splits a group that fits a page, keeps a round heading with its first group and repeats a carried-on round or group as "(Continued)". The report picks the orientation itself until the director chooses one (`ReportSpec.suggestedOrientation`, which the other reports leave at their default): Portrait when every column fits across it at its narrowest, Landscape otherwise. Columns that still do not fit are drawn at their narrowest and continue on further pages, whole columns only, with the same rows, column headings and round and group headings on each page of a band so pages taped side by side line up (nothing repeats the pilot). A retired pilot (`retiredAtRound` is the first round they no longer fly) is left out of the rounds from then on; with Include retired pilots the name carries "(R)". Pre-fill prints entered scores (unofficial ones with an asterisk, shaded and in bold monospace so a printer that drops grey loses nothing) and is off until a score exists. A legend line under the table (only when a mark needs it: "(R) = retired", "Includes scores through round N · * not official") sits above the frame's standard footer; the sheet uses the standard header and footer. Print and Save as PDF go through `ReportPrinter` (`services/reports/viewer/`); the app uses `PlatformReportPrinter`, held in `ReportPrinters.current` so an E2E journey can swap the two system dialogs for recorders. Engine (decided 2026-10-21, #476): raster. `RasterReportPdfBuilder` (behind the `ReportPdfBuilder` interface) paints each finished sheet page in an off-screen render tree and places it in the PDF as an image, so the printout matches the sheet exactly and each report has one layout; PDF text is not selectable or searchable. If testers ask for that, add a vector `ReportPdfBuilder` for one report at a time (start with the standings table) and keep the raster one as the fallback. The Page group has "Pages to print" (`pp` in the URL, parsed by `PrintPageRange`): blank for every page, or `1` or `2-4`; `printing` cannot pick pages of a sheet the app draws, so the viewer sends only those pages, and Print and Save as PDF are off while the text is not a range of the sheet. On Windows the print dialog is the classic Print Setup one, not the newer `windowsModernDialog` one, which ignores the paper size and orientation the app asks for and starts from the printer's defaults; the classic dialog's Properties button reaches the printer's own double-sided and colour options, which the app cannot set itself. Print uses `printing`'s `layoutPdf` (the web reports nothing after its dialog, so the viewer stays quiet); Save as PDF downloads in the browser (`sharePdf`) and uses a save dialog (`file_selector`) on Windows, because `printing` cannot share on Windows. The Windows build of `printing` downloads a pdfium binary at build time; on the web it loads pdf.js from a CDN only for its own PDF rasteriser, which this app does not use.
- The Scoring route takes optional `?round=N&group=G` (built by `contestScoringPath`); the next-step card and the progress card's tiles use it. The page is official F5J score entry for one group (#123): round and group navigation, a row per pilot saved on its own, Score check, and the save, conflict and not-permitted states. Its state lives in `services/scoring/` (`ScoringController`); lock and mark-official actions are not built yet because the API has none. The row menu opens the score history (`GET .../assignments/:id/scores/history`) and retires or reinstates the pilot from the round in view (a participation update, which recalculates the results); the group menu opens the group's history (#432).
- The account control sits at the bottom of the rail (`widgets/shell_account_button.dart`): the user's picture with a menu (name, Settings, Sign out) when signed in, a gear otherwise (offline: menu with Sign in and Settings). Settings opens the Settings page (`/contest-administration/settings`, system scope, no rail entry): the theme choice (System, Light, Dark; `ThemeController` in `services/theme/`, kept per account in the `LocalUiStore`) and the text size (Default, Large, Extra large; `TextSizeController` in `services/text_size/`, kept the same way). `app.dart` applies the size in the `MaterialApp.router` builder through `PreferredTextScaler`, which multiplies the device's text scale by 1, 1.25 or 1.5 and caps the product at 2.5, so layouts must wrap, stack or scroll instead of assuming a text height; `test/server/text_size_layout_test.dart` sweeps the key pages at every size and fails on any overflow (add a new page to its route list). It also holds the account's preferred time zone and locale (`PreferencesController` in `services/preferences/`, `preferencesOf(context)`; saved to the account through `AppBootstrap.savePreferences`) and "Reset panels to defaults" for the remembered hidden and minimized panels (`CollapsibleAreasController` in `services/collapsible_areas/`, one stored choice map per account, shared by all contests; register each new collapsible panel in `collapsibleAreas` and read it with `collapsibleAreasOf(context)`). Times shown to the director (last saved, last synced, history) go through `DirectorTime.of(context)` so they follow the preferred zone and locale; times pilots see keep using `ContestTime` with the contest's zone. User-visible text goes in `lib/l10n/app_en.arb`. `UiAccount` (`services/ui_account/`, `uiAccountOf(context)`) names the account whose UI-only state to read and write; use it as the account id for every `LocalUiStore` call.
- The participant editor is one page with three section cards (`widgets/participant_editor/`), its state and API calls in `ParticipantEditorController` (`services/participants/`). Validation shows per field once left and as a summary after a save attempt; a matching email is a decision panel (Use existing / Change the email; two participants cannot share an email), not an error; a stale revision offers Reload or a field-by-field review; Save is off in edit until something changed; add mode has Save and add another, which keeps club and location. The storage chip comes from `AppSync` (native only). `remoteMatchingUnavailable` and `managedFields` on the page are built but not wired until #247.
- Rail and header code: `widgets/shell_rail.dart` (destinations and create button), `shell_header.dart` (breadcrumbs), `shell_status_panel.dart`, `shell_stub_page.dart`.
- The contest Participants page (`pages/contest/participants_page.dart`, state in `services/contest_participants/`, `ParticipantsController`) lists the stored people with the wizard's list widgets (`widgets/participants/`). Role, class and team edits wait behind the Save bar (`participants_save_bar.dart`) and save row by row (`PUT .../participations/{id}` for role and class with the revision the row was read at, team memberships for the team); adding (search or the participant editor, with a role choice and the late-add warning after the draw) and removing act at once. A pilot has flights when any score slot of theirs is past not entered (read from `GET .../scores`); that blocks Remove and a non-flying role (`has_scores` from the server). A drawn pilot with no scores can still be removed or made non-flying: the server removes their matrix rows and empty score slots with a tombstone each and leaves the matrix revision alone (`ParticipationsService`, `MatrixAssignmentRepository.removeForParticipation`; the answer carries `matrix_rows_removed`), the confirmations say so, and `banner-redo-draw` leads to the Matrix page's redraw. How a row is drawn beyond its values (edited cells, state, note, locks) comes from `ParticipantRowStyle` (`participants_row_styles.dart`). Class is required for scoring pilots when classes are on. A pilot who joins a drawn contest (added, or changed from a non-flying role) is put in the last group that can take them in every round through `POST .../matrix/late-placements` (`LatePlacementService`: a normal late add per round, going back to earlier groups when one is full, locked, flown or holds a teammate; a round already fully scored gets them in its last group with a blank, zero official score; a round no group can take them in is reported and left to the Matrix page, which only older data reaches: the server refuses the add or the change to a pilot role with 409 `no_room_in_round` when a round that is not fully scored has no group with room, since a group holds `ceil(originals / groups)` pilots and unseated pilots take open seats first, `LateAddCapacity`; the page keeps the add failure banner with the server's text). With no scores yet the page first offers to redraw the matrix with them; declining places them anyway. Completed contests are read-only. Each pilot's models are edited in a window (`widgets/participants/pilot_models_dialog.dart`, backends in `services/participants/pilot_models_backend.dart`) that saves as it goes (`/contests/{id}/model-links`); pending-deletion is not built.
- The wizard's Participants step (step 4) lives in `widgets/new_contest/participants/`; its table, cards, cells, team combobox, bulk bar and search field are shared (`widgets/participants/`, over the `ParticipantRow` and `ParticipantListRules` interfaces in `services/participants/`) so the contest Participants page can reuse them. Email shows as a status (Has email, None, Private), never as an address. The Models column opens the same window over the draft; the models are sent when the contest is created (a typed one is also added to the person's profile) and a pilot without one only shows a notice.
- The workspace page is a frame of section and control slots (`widgets/workspace/`) arranged by `WorkspaceLayoutPlan` (`services/workspace/`). It has no page-card list; links sit next to the fact they act on. The controls column starts with the status summary (labelled lifecycle, scoring, administration, publication, visibility, results hiding and local archive values) and holds the lifecycle, scoring and administration cards (`widgets/workspace/controls/`, rules in `services/workspace/controls/`); lock and complete ask first, and the archive card is disabled because the API has no archive action. The next-step card and the control cards share `ContestActionRunner` and the snackbar texts in `contest_transition.dart`.
- The workspace's Recent activity card (`widgets/workspace/activity/`, rules in `services/workspace/activity/`) lists the newest audit events (state transitions and successful publication events; the actor shows as "you" only for the acting account) read once with the workspace facts (`ActivityFacts`); a failed read shows a retry in the card only. View all is disabled until the audit page exists. Configuration, matrix and score-correction events are not written yet.
- The "Sync" rail entry and the sync item in the status panel appear only in builds that synchronize (native). Screens reach sync through `AppSync` (`services/sync/`), never the sync package. A refused change or open conflict adds a row to the workspace needs-attention list that links to the sync page. The sync page also lists the open conflicts and decides each in a dialog (`widgets/sync/conflict_resolve_dialog.dart`).
- Opening a contest from the list goes through `ContestOpenAction` / `contestOpenPath`, which picks the page by contest state.

### Public site (`soar_score_web`)

A Next.js app (App Router, TypeScript; ADR 0005), not Flutter: marketing and information, docs and help, support, and the published results. Routes are files under `src/app/`; every route renders inside the root layout's header and footer (`src/components/site-header.tsx`, `site-footer.tsx`); unknown routes show `src/app/not-found.tsx`. `next.config.ts` redirects `/results` to `/results/contests` and `/help` to `/docs`. Run with `npm run dev` in `apps/soar_score_web` (see its `AGENTS.md`).

| Name people use                                                       | Route                                                                                 | Source (`src/app/`)                                                          |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Site home, landing, homepage                                          | `/`                                                                                   | `page.tsx`, sections in `src/components/home/`                               |
| Contests, contest search (`?name=&venue=&from=&to=` filters)          | `/results/contests`                                                                   | `results/contests/page.tsx`, `src/components/results/`                       |
| Not found (not a route)                                               | none                                                                                  | `not-found.tsx`                                                              |
| Contest results, overall individual results (as of a round)           | `/results/contests/:contestId`, `/results/contests/:contestId/rounds/:roundNumber`    | `results/contests/[contestId]/page.tsx`, `.../rounds/[roundNumber]/page.tsx` |
| Team scores, team results (as of a round)                             | `/results/contests/:contestId/teams/results`, `.../teams/results/rounds/:roundNumber` | `results/contests/[contestId]/teams/results/...`                             |
| Flight group scores, groups of a round (`?pilot=` scrolls to a pilot) | `/results/contests/:contestId/rounds/:roundNumber/flight-groups`                      | `results/contests/[contestId]/rounds/[roundNumber]/flight-groups/page.tsx`   |
| Contest not found (unknown or delisted, shown in place)               | none                                                                                  | `src/components/results/contest-not-found.tsx`                               |
| Contest not visible (pending or private, re-checks every 15 minutes)  | none                                                                                  | `src/components/results/contest-not-visible.tsx`                             |

The contest views share `results/contests/[contestId]/layout.tsx`, a client provider that loads the publication once per contest, so moving between views or rounds keeps the loaded contest. Parsed models live in `src/lib/results/` (`published-contest.ts`, `contest-summary.ts`, `contest-filters.ts`, `paths.ts`); components never read the raw projection maps. The flight-group table reads the provisional `raw_components` (#456) and `reflight` (#457) score keys and hides those columns until the server emits them.

Documentation, help and support (spec: `plan/ui/public-site/docs-help.md`, `support.md`) share `docs/layout.tsx` (sidebar navigation from `src/components/docs/topics.ts`). Content is draft copy pending #165 and carries a note saying so.

| Name people use                                    | Route                                       | Source (`src/app/`)                                    |
| -------------------------------------------------- | ------------------------------------------- | ------------------------------------------------------ |
| Docs landing, help landing                         | `/docs` (`/help` redirects here)            | `docs/page.tsx`                                        |
| Contest Director Getting Started, competition help | `/docs/competitions`                        | `docs/competitions/page.tsx`                           |
| Help Me Enter My Score, participant scoring help   | `/docs/participant-scoring`                 | `docs/participant-scoring/page.tsx`                    |
| F5J score entry quick reference                    | `/docs/participant-scoring/disciplines/f5j` | `docs/participant-scoring/disciplines/f5j/page.tsx`    |
| I Need An Account?, user account help              | `/docs/user-accounts`                       | `docs/user-accounts/page.tsx`                          |
| Finding Contests and Results, public contests help | `/docs/contests-and-scores`                 | `docs/contests-and-scores/page.tsx`                    |
| Docs not found (any unknown route under `/docs`)   | `/docs/not-found`                           | `docs/not-found/page.tsx` (`docs/[...rest]` redirects) |
| Support, request support                           | `/support`                                  | `support/page.tsx`, `src/components/support/`          |

### Self-scoring app (`soar_score_self_score`)

| Name people use                                           | Route                                                        | Source (`lib/`)                  |
| --------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------- |
| Landing page (Sign in / Sign up)                          | `/`                                                          | `pages/home_page.dart`           |
| Contests list, "Is this you?"                             | `/contests`                                                  | `pages/contests_page.dart`       |
| Application info (licences, Privacy Policy, Terms)        | `/app-info`                                                  | `pages/app_info_page.dart`       |
| Invitation link (guest session)                           | `/invitations/:credential`                                   | `pages/invitation_page.dart`     |
| Contest entry (guest: pilot overview; else team overview) | `/contests/:contestId`                                       | `router.dart`                    |
| Team overview (helper view, team standings)               | `/contests/:contestId/team`                                  | `pages/team_page.dart`           |
| Pilot overview (round cards, retire)                      | `/contests/:contestId/pilots/:pilotId`                       | `pages/pilot_overview_page.dart` |
| Score entry (F5J form, landing sheet/combobox)            | `/contests/:contestId/pilots/:pilotId/rounds/:roundId`       | `pages/score_entry_page.dart`    |
| Group results (not in the spec's route table)             | `/contests/:contestId/pilots/:pilotId/rounds/:roundId/group` | `pages/group_results_page.dart`  |
| Results (latest, or `?round=N` as of a round)             | `/contests/:contestId/results`                               | `pages/results_page.dart`        |

Routes follow `plan/ui/participant-scoring/participant-scoring.md`. The invitation handler checks the link, then Continue as guest stores the guest session (`session/`, browser local storage) and replaces the address with the pilot overview; Sign in and Create account are inert until #545/#546. The app uses path URLs (not `#/`), so `apps/soar_score_self_score/wrangler.jsonc` turns on the SPA fallback and the page sends no referrer. Contest entry sends a guest to their pilot overview and everyone else to the team overview until accounts and helpers exist. On the pilot overview, View opens the group results for the round until the read-only score view exists; Copy invitation link and Retire are not connected to the API. The path helpers are at the top of `router.dart`.

Pages read through `SelfScoreRepository` (`data/self_score_repository.dart`, provided by `SelfScoreScope`) and load with `LoadableScaffold` (loading, error and Retry states). `main.dart` provides `ApiSelfScoreRepository` (`data/api_self_score_repository.dart`, over the `/api/v1/self-scoring/*` calls on `ApiClient`; the guest session token is the client's bearer token). `SampleSelfScoreRepository`, backed by `data/sample_data.dart`, stays for tests and design review (`--dart-define=SOAR_SCORE_SAMPLE_DATA=true`). Score entry submits through `SelfScoreRepository.submitScore` with a client mutation id; the form keeps a draft in browser storage (`session/score_draft_store.dart`) and sends a queued score again with the same id. The contests list and team overview show a coming-soon message on the API repository, and the results page hides the Teams toggle when there are no team standings. The landing field picks its control by table size (`widgets/landing_control.dart`: sheet up to 20 results, autocomplete above); see `plan/ui/participant-scoring/landing-control-decision.md`.

### Server (`soar_score_server`)

The server has no pages. Its HTTP routes (`/roles`, `/participants`, `/landing-tables`, `/health`, public `/publications`, and so on) are defined in `packages/soar_score_api_handlers/lib/handlers/`.

Keep this section current: a PR that adds, renames or moves a page route updates the table.

## Demo Data

The demo database (`packages/soar_score_data/lib/seeding/demo/`) must keep showing every feature that has data. A PR that adds or changes a model, repository or service the demo can use must update the demo seeder, or add the repository to the exemptions in `packages/soar_score_data/test/seeding/demo_coverage_test.dart` with the reason and the issue that will bring it in. That test fails for a repository that is neither seeded nor exempt. Open items are tracked in #305.

## Getting Help

- Review `analysis_options.yaml` for linting rules
- Consult Flutter documentation: https://docs.flutter.dev/
- Consult Dart documentation: https://dart.dev/
- Consult Melos documentation: https://melos.invertase.dev/commands

## Style guidelines

When creating files keep them targeted to the domain at hand. Do not place many classes in a single file. Test case files should be broken into manageable sizes.
