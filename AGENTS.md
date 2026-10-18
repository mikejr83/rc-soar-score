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

| Name people use                                                      | Route                                                | Source (`lib/`)                                                   |
| -------------------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------------------- |
| Landing page (sign in / "Continue offline"), no shell                | `/contest-administration`                            | `pages/landing_page.dart`                                         |
| Main page, contests page, contest list ("Contests" rail entry)       | `/contest-administration/home`                       | `pages/home_page.dart`, `widgets/contest_list.dart`               |
| New contest wizard (rail "Create contest" button)                    | `/contest-administration/contests/new`               | `pages/new_contest_wizard_page.dart`, `widgets/new_contest/`      |
| Workspace (contest scope, "Workspace" rail entry)                    | `/contest-administration/contests/:id/workspace`     | `pages/contest_workspace_page.dart`                               |
| Contest configuration page ("Configuration" rail entry)              | `/contest-administration/contests/:id/configuration` | `pages/contest_configuration_page.dart`, `widgets/configuration/` |
| Matrix page, draw ("Matrix" rail entry)                              | `/contest-administration/contests/:id/matrix`        | `pages/matrix_page.dart`, `widgets/matrix/`                       |
| Contest participants page (contest scope, "Participants" rail entry) | `/contest-administration/contests/:id/participants`  | `pages/contest/participants_page.dart`                            |
| Contest scoring page (contest scope, "Scoring" rail entry)           | `/contest-administration/contests/:id/scoring`       | `pages/contest/scoring_page.dart`, `widgets/scoring/`             |
| Contest reports page (contest scope, "Reports" rail entry)           | `/contest-administration/contests/:id/reports`       | `pages/contest/reports_page.dart`                                 |
| Contest sync page (contest scope, "Sync" rail entry, native only)    | `/contest-administration/contests/:id/sync`          | `pages/contest/sync_page.dart`, `widgets/sync/`                   |
| Participants manager ("Participants" rail entry)                     | `/contest-administration/participants`               | `pages/participants_page.dart`                                    |
| Participant editor (new / edit)                                      | `/contest-administration/participants/new`, `/:id`   | `pages/participant_editor_page.dart`                              |
| Role manager ("Roles" rail entry)                                    | `/contest-administration/roles`                      | `pages/roles_page.dart`, `widgets/roles/`                         |
| Landings manager ("Landings" rail entry)                             | `/contest-administration/landings`                   | `pages/landings_page.dart`, `widgets/landings/`                   |
| Landing table editor (new / copy)                                    | `/contest-administration/landings/new`               | `pages/landing_editor_page.dart`                                  |
| Startup failure page (not a route)                                   | none                                                 | `pages/bootstrap_failure_page.dart`                               |

Notes:

- "Configuration page" always means the contest-scoped page above, not the draft step inside the wizard.
- The contest-scoped "Reports" page is a placeholder that shows only the contest ID; its rail entry and route are in place.
- The Scoring route takes optional `?round=N&group=G` (built by `contestScoringPath`); the next-step card and the progress card's tiles use it. The page is official F5J score entry for one group (#123): round and group navigation, a row per pilot saved on its own, Score check, and the save, conflict and not-permitted states. Its state lives in `services/scoring/` (`ScoringController`); lock and mark-official actions are not built yet because the API has none.
- The account control sits at the bottom of the rail (`widgets/shell_account_button.dart`): the user's picture with a menu (name, Settings, Sign out) when signed in, a gear otherwise (offline: menu with Sign in and Settings). Settings is a not-built dialog for now.
- Rail and header code: `widgets/shell_rail.dart` (destinations and create button), `shell_header.dart` (breadcrumbs), `shell_status_panel.dart`, `shell_stub_page.dart`.
- The workspace page is a frame of section and control slots (`widgets/workspace/`) arranged by `WorkspaceLayoutPlan` (`services/workspace/`). It has no page-card list; links sit next to the fact they act on.
- The "Sync" rail entry and the sync item in the status panel appear only in builds that synchronize (native). Screens reach sync through `AppSync` (`services/sync/`), never the sync package. A refused change or open conflict adds a row to the workspace needs-attention list that links to the sync page. The sync page also lists the open conflicts and decides each in a dialog (`widgets/sync/conflict_resolve_dialog.dart`).
- Opening a contest from the list goes through `ContestOpenAction` / `contestOpenPath`, which picks the page by contest state.

### Public site (`soar_score_public`)

Every route renders inside the site shell (`widgets/site_shell.dart`: header with logo, app name and navigation, footer) via a go_router `ShellRoute`; unknown routes show `pages/site/not_found_page.dart` (router `errorBuilder`). `/results` redirects to `/results/contests`.

| Name people use                     | Route               | Source (`lib/`)                   |
| ----------------------------------- | ------------------- | --------------------------------- |
| Site home, landing, homepage        | `/`                 | `pages/site/landing_page.dart`    |
| Contests (search, placeholder #434) | `/results/contests` | `pages/results/results_page.dart` |
| Not found (not a route)             | none                | `pages/site/not_found_page.dart`  |

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

| Name people use | Route     | Source (`lib/`)               |
| --------------- | --------- | ----------------------------- |
| Home            | `/`       | `pages/home_page.dart`        |
| Score entry     | `/scores` | `pages/score_entry_page.dart` |

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
