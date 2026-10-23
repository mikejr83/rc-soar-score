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

Soar Score is an RC sailplane soaring contest scoring and management suite. It consists of multiple Flutter and Dart applications and shared packages, all managed by Melos in a Dart monorepo.

**Tech Stack:**

- Flutter
- Dart
- Melos

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
  `scripts/e2e.ps1` (or `scripts/e2e.sh`; `-d web` / `-Device web` runs them in headless Chrome against a token-free test server, see `apps/soar_score_contest/AGENTS.md`). CI never runs them: `melos test`
  runs `test/` only. See `apps/soar_score_contest/AGENTS.md`.
- **Keep the E2E tests current.** After any change to the contest app's pages,
  routes, widget keys, visible labels, flows or demo data, run
  `scripts/e2e.ps1` and fix or extend the journeys the change affects, in the
  same PR. A change that adds a page or flow gets a journey for it.

## Code Style & Linting

- All projects use `analysis_options.yaml` at their root
- Flutter apps include `package:flutter_lints/flutter.yaml`
- Dart CLI projects include `package:lints/recommended.yaml`
- Run `melos analyze` to check

## CI/CD

- GitHub Actions workflow in `.github/workflows/ci.yml` (owned by ticket 011)
- Runs on push/PR to `master`
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

| Name people use                                                      | Route                                                  | Source (`lib/`)                                                     |
| -------------------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------- |
| Landing page (sign in / "Continue offline"), no shell                | `/contest-administration`                              | `pages/landing_page.dart`                                           |
| Main page, contests page, contest list ("Contests" rail entry)       | `/contest-administration/home`                         | `pages/home_page.dart`, `widgets/contest_list.dart`                 |
| New contest wizard (rail "Create contest" button)                    | `/contest-administration/contests/new`                 | `pages/new_contest_wizard_page.dart`, `widgets/new_contest/`        |
| Workspace (contest scope, "Workspace" rail entry)                    | `/contest-administration/contests/:id/workspace`       | `pages/contest_workspace_page.dart`                                 |
| Contest configuration page ("Configuration" rail entry)              | `/contest-administration/contests/:id/configuration`   | `pages/contest_configuration_page.dart`, `widgets/configuration/`   |
| Matrix page, draw ("Matrix" rail entry)                              | `/contest-administration/contests/:id/matrix`          | `pages/matrix_page.dart`, `widgets/matrix/`                         |
| Contest participants page (contest scope, "Participants" rail entry) | `/contest-administration/contests/:id/participants`    | `pages/contest/participants_page.dart`                              |
| Contest scoring page (contest scope, "Scoring" rail entry)           | `/contest-administration/contests/:id/scoring`         | `pages/contest/scoring_page.dart`, `widgets/scoring/`               |
| Contest reports page (contest scope, "Reports" rail entry)           | `/contest-administration/contests/:id/reports`         | `pages/contest/reports_page.dart`                                   |
| Report viewer (outside the shell; opens from a report card)          | `/contest-administration/contests/:id/reports/:report` | `pages/contest/report_viewer_page.dart`, `widgets/reports/viewer/`  |
| Contest sync page (contest scope, "Sync" rail entry, native only)    | `/contest-administration/contests/:id/sync`            | `pages/contest/sync_page.dart`, `widgets/sync/`                     |
| Participants manager ("Participants" rail entry)                     | `/contest-administration/participants`                 | `pages/participants_page.dart`                                      |
| Participant editor (new / edit)                                      | `/contest-administration/participants/new`, `/:id`     | `pages/participant_editor_page.dart`, `widgets/participant_editor/` |
| Role manager ("Roles" rail entry)                                    | `/contest-administration/roles`                        | `pages/roles_page.dart`, `widgets/roles/`                           |
| Landings manager ("Landings" rail entry)                             | `/contest-administration/landings`                     | `pages/landings_page.dart`, `widgets/landings/`                     |
| Settings page (account control at the bottom of the rail)            | `/contest-administration/settings`                     | `pages/settings_page.dart`, `widgets/settings/`                     |
| Landing table editor (new / copy)                                    | `/contest-administration/landings/new`                 | `pages/landing_editor_page.dart`                                    |
| Startup failure page (not a route)                                   | none                                                   | `pages/bootstrap_failure_page.dart`                                 |

Notes:

- Settings opens from the account control and keeps the current scope: `/contest-administration/settings` outside a contest, `/contest-administration/contests/:id/settings` (`contestSettingsPath`) inside one, so the contest rail stays.
- "Configuration page" always means the contest-scoped page above, not the draft step inside the wizard.
- The contest-scoped "Reports" page lists the four reports (`widgets/reports/`, state in `services/reports/`): a context strip (lifecycle, scoring progress, result status with its help popover), then a card per report under Results and Documents to print. A report that cannot be produced shows a disabled Open with its reason and a link; warnings (preliminary scores, configuration drift, undrawn seeded rounds) sit on the card. Open launches the viewer through `ReportLauncher` (`services/reports/`): its own browser tab on the web (with a blocked-pop-up fallback, Open here), in place with Back to Reports on native. The viewer (`ReportViewerPage`) is a reusable frame: filters, options and page setup live in the URL query, the sheet is an unthemed paper page, and each report supplies a `ReportDefinition` (controls and pages). A report that reads data of its own overrides `dataKey` and `loadData` on `ReportSpec`; the viewer reads the data again only when the key changes. Overall Standings (`widgets/reports/standings/`, rules in `services/reports/standings/`) is built: it shows the stored standing as of the last round shown, read from `GET /contests/{id}/results?asOfRound=N`, and never recalculates. The other reports are `PlaceholderReport`s until their content briefs are built. Print and Save as PDF go through `ReportPrinter` (`services/reports/viewer/`); the app uses `PlatformReportPrinter`, held in `ReportPrinters.current` so an E2E journey can swap the two system dialogs for recorders. Engine (decided 2026-10-21, #476): raster. `RasterReportPdfBuilder` (behind the `ReportPdfBuilder` interface) paints each finished sheet page in an off-screen render tree and places it in the PDF as an image, so the printout matches the sheet exactly and each report has one layout; PDF text is not selectable or searchable. If testers ask for that, add a vector `ReportPdfBuilder` for one report at a time (start with the standings table) and keep the raster one as the fallback. Print uses `printing`'s `layoutPdf` (the web reports nothing after its dialog, so the viewer stays quiet); Save as PDF downloads in the browser (`sharePdf`) and uses a save dialog (`file_selector`) on Windows, because `printing` cannot share on Windows. The Windows build of `printing` downloads a pdfium binary at build time; on the web it loads pdf.js from a CDN only for its own PDF rasteriser, which this app does not use.
- The Scoring route takes optional `?round=N&group=G` (built by `contestScoringPath`); the next-step card and the progress card's tiles use it. The page is official F5J score entry for one group (#123): round and group navigation, a row per pilot saved on its own, Score check, and the save, conflict and not-permitted states. Its state lives in `services/scoring/` (`ScoringController`); lock and mark-official actions are not built yet because the API has none. The row menu opens the score history (`GET .../assignments/:id/scores/history`) and retires or reinstates the pilot from the round in view (a participation update, which recalculates the results); the group menu opens the group's history (#432).
- The account control sits at the bottom of the rail (`widgets/shell_account_button.dart`): the user's picture with a menu (name, Settings, Sign out) when signed in, a gear otherwise (offline: menu with Sign in and Settings). Settings opens the Settings page (`/contest-administration/settings`, system scope, no rail entry): the theme choice (System, Light, Dark; `ThemeController` in `services/theme/`, kept per account in the `LocalUiStore`). It also holds the account's preferred time zone and locale (`PreferencesController` in `services/preferences/`, `preferencesOf(context)`; saved to the account through `AppBootstrap.savePreferences`) and "Reset panels to defaults" for the remembered hidden and minimized panels (`CollapsibleAreasController` in `services/collapsible_areas/`, one stored choice map per account, shared by all contests; register each new collapsible panel in `collapsibleAreas` and read it with `collapsibleAreasOf(context)`). Times shown to the director (last saved, last synced, history) go through `DirectorTime.of(context)` so they follow the preferred zone and locale; times pilots see keep using `ContestTime` with the contest's zone. User-visible text goes in `lib/l10n/app_en.arb`. `UiAccount` (`services/ui_account/`, `uiAccountOf(context)`) names the account whose UI-only state to read and write; use it as the account id for every `LocalUiStore` call.
- The participant editor is one page with three section cards (`widgets/participant_editor/`), its state and API calls in `ParticipantEditorController` (`services/participants/`). Validation shows per field once left and as a summary after a save attempt; a matching email is a decision panel (Use existing / Change the email; two participants cannot share an email), not an error; a stale revision offers Reload or a field-by-field review; Save is off in edit until something changed; add mode has Save and add another, which keeps club and location. The storage chip comes from `AppSync` (native only). `remoteMatchingUnavailable` and `managedFields` on the page are built but not wired until #247.
- Rail and header code: `widgets/shell_rail.dart` (destinations and create button), `shell_header.dart` (breadcrumbs), `shell_status_panel.dart`, `shell_stub_page.dart`.
- The workspace page is a frame of section and control slots (`widgets/workspace/`) arranged by `WorkspaceLayoutPlan` (`services/workspace/`). It has no page-card list; links sit next to the fact they act on. The controls column starts with the status summary (labelled lifecycle, scoring, administration, publication, visibility, results hiding and local archive values) and holds the lifecycle, scoring and administration cards (`widgets/workspace/controls/`, rules in `services/workspace/controls/`); lock and complete ask first, and the archive card is disabled because the API has no archive action. The next-step card and the control cards share `ContestActionRunner` and the snackbar texts in `contest_transition.dart`.
- The "Sync" rail entry and the sync item in the status panel appear only in builds that synchronize (native). Screens reach sync through `AppSync` (`services/sync/`), never the sync package. A refused change or open conflict adds a row to the workspace needs-attention list that links to the sync page. The sync page also lists the open conflicts and decides each in a dialog (`widgets/sync/conflict_resolve_dialog.dart`).
- Opening a contest from the list goes through `ContestOpenAction` / `contestOpenPath`, which picks the page by contest state.

### Public site (`soar_score_public`)

Every route renders inside the site shell (`widgets/site_shell.dart`: header with logo, app name and navigation, footer) via a go_router `ShellRoute`; unknown routes show `pages/site/not_found_page.dart` (router `errorBuilder`). `/results` redirects to `/results/contests`.

| Name people use                                                       | Route                                                                                 | Source (`lib/`)                                                              |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Site home, landing, homepage                                          | `/`                                                                                   | `pages/site/landing_page.dart`                                               |
| Contests, contest search (`?name=&venue=&from=&to=` filters)          | `/results/contests`                                                                   | `pages/results/results_page.dart`, `widgets/results/`                        |
| Not found (not a route)                                               | none                                                                                  | `pages/site/not_found_page.dart`                                             |
| Contest results, overall individual results (as of a round)           | `/results/contests/:contestId`, `/results/contests/:contestId/rounds/:roundNumber`    | `pages/results/contest_page.dart`, `widgets/results/`                        |
| Team scores, team results (as of a round)                             | `/results/contests/:contestId/teams/results`, `.../teams/results/rounds/:roundNumber` | `pages/results/contest_page.dart`, `widgets/results/team_results_table.dart` |
| Flight group scores, groups of a round (`?pilot=` scrolls to a pilot) | `/results/contests/:contestId/rounds/:roundNumber/flight-groups`                      | `pages/results/contest_page.dart`, `widgets/results/flight_group_table.dart` |
| Contest not found (unknown or delisted, shown in place)               | none                                                                                  | `pages/results/contest_not_found_page.dart`                                  |
| Contest not visible (pending or private, re-checks every 15 minutes)  | none                                                                                  | `pages/results/contest_not_visible_page.dart`                                |

Contest routes live in `lib/contest_routes.dart` (`contestRoutes`, `contestResultsPath`, `contestTeamResultsPath`, `contestFlightGroupsPath`); the `:contestId` segment carries the publication id. All contest views are one `ContestPage` (`view` picks `ContestView.overall`, `teams` or `flightGroups`) under one page key, so moving between views or rounds keeps the loaded contest. The round selector (`widgets/results/round_selector.dart`) is shared by every view; a round header or round score in the overall and team tables opens that round's flight groups. A team-less contest's team route redirects to the contest root. Parsed view models live in `lib/models/results/`; widgets never read the raw projection maps. The flight-group table reads the provisional `raw_components` (#456) and `reflight` (#457) score keys and hides those columns until the server emits them.

Documentation, help and support routes are registered in `lib/docs_routes.dart` (spec: `plan/ui/public-site/docs-help.md`, `support.md`). `/help` only redirects to `/docs`.

| Name people use                                    | Route                                       | Source (`lib/`)                            |
| -------------------------------------------------- | ------------------------------------------- | ------------------------------------------ |
| Docs landing, help landing                         | `/docs` (`/help` redirects here)            | `pages/docs/docs_landing_page.dart`        |
| Contest Director Getting Started, competition help | `/docs/competitions`                        | `pages/docs/competitions_page.dart`        |
| Help Me Enter My Score, participant scoring help   | `/docs/participant-scoring`                 | `pages/docs/participant_scoring_page.dart` |
| F5J score entry quick reference                    | `/docs/participant-scoring/disciplines/f5j` | `pages/docs/f5j_scoring_page.dart`         |
| I Need An Account?, user account help              | `/docs/user-accounts`                       | `pages/docs/user_accounts_page.dart`       |
| Finding Contests and Results, public contests help | `/docs/contests-and-scores`                 | `pages/docs/contests_and_scores_page.dart` |
| Docs not found (any unknown route under `/docs`)   | `/docs/not-found`                           | `pages/docs/docs_not_found_page.dart`      |
| Support, request support                           | `/support`                                  | `pages/support/support_page.dart`          |

### Self-scoring app (`soar_score_self_score`)

| Name people use                                | Route                                                        | Source (`lib/`)                  |
| ---------------------------------------------- | ------------------------------------------------------------ | -------------------------------- |
| Landing page (Sign in / Sign up)               | `/`                                                          | `pages/home_page.dart`           |
| Contests list, "Is this you?"                  | `/contests`                                                  | `pages/contests_page.dart`       |
| Contest entry (redirects to the team overview) | `/contests/:contestId`                                       | `router.dart`                    |
| Team overview (helper view, team standings)    | `/contests/:contestId/team`                                  | `pages/team_page.dart`           |
| Pilot overview (round cards, retire)           | `/contests/:contestId/pilots/:pilotId`                       | `pages/pilot_overview_page.dart` |
| Score entry (F5J form, landing sheet/combobox) | `/contests/:contestId/pilots/:pilotId/rounds/:roundId`       | `pages/score_entry_page.dart`    |
| Group results (not in the spec's route table)  | `/contests/:contestId/pilots/:pilotId/rounds/:roundId/group` | `pages/group_results_page.dart`  |
| Results (latest, or `?round=N` as of a round)  | `/contests/:contestId/results`                               | `pages/results_page.dart`        |

Routes follow `plan/ui/participant-scoring/participant-scoring.md`. Not built yet: the invitation handler (`/invitations/{credential}`). Contest entry sends everyone to the team overview until role routing exists (#142). On the pilot overview, View opens the group results for the round until the read-only score view exists; Copy invitation link and Retire are not connected to the API. The path helpers are at the top of `router.dart`.

The pages read placeholder data from `models/sample_data.dart` until the self-scoring API exists. The landing field picks its control by table size (`widgets/landing_control.dart`: sheet up to 20 results, autocomplete above); see `plan/ui/participant-scoring/landing-control-decision.md`.

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
