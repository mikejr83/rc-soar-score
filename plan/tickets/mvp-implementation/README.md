# MVP Implementation — Repository Setup Tickets

Tickets for getting the repository basics in place: toolchain, Melos workspace, the three apps and four shared packages, Auth0 identity, CI/CD, and agentic-coding rules. These are _implementation work_ tickets (work items with checkboxes), distinct from the decision tickets in `../pre-implementation/`.

## How to use

- Each ticket has **Category**, **Priority**, **Status**, **Context**, **Work Items** (checkboxes), **Acceptance Criteria**, **Dependencies**, and **Sources**.
- Work through dependencies first. A ticket is done when every Work Item and Acceptance Criterion checkbox is ticked and its `Status` is flipped to `Decided` — use `Done` instead for this folder: flip `Status` from `Open` to `Done` when complete.
- Tickets superseded by a newer approach are marked `Rejected` (see 002 — NX, and 012 — Playwright, both replaced by native Dart/Flutter tooling with Melos for monorepo management).
- Versions are never guessed at execution time: if a pin recorded in ticket 001 is stale, update ticket 001 first, then anything that references it.

## Index

| Ticket                                               | Title                                                                                                                                                      | Priority | Status    |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | --------- |
| [001](001-setup-toolchain-baseline.md)               | Toolchain and Version Baseline                                                                                                                             | High     | Done      |
| [002](002-scaffold-nx-workspace.md)                  | ~~NX Workspace at Repository Root~~ (replaced by 014)                                                                                                      | High     | Rejected  |
| [003](003-scaffold-dart-api-app.md)                  | Scaffold `soar_score_server` (Dart/shelf)                                                                                                                  | High     | Done      |
| [004](004-scaffold-contest-flutter-app.md)           | Scaffold `soar_score_contest` (Flutter web)                                                                                                                | High     | In-Review |
| [005](005-scaffold-public-flutter-app.md)            | Scaffold `soar_score_public` (Flutter web)                                                                                                                 | High     | Open      |
| [006](006-scaffold-core-package.md)                  | Scaffold `soar_score_core` Package                                                                                                                         | High     | In-Review |
| [007](007-scaffold-data-package.md)                  | Scaffold `soar_score_data_sqlite` Package                                                                                                                  | High     | In-Review |
| [008](008-scaffold-api-package.md)                   | Scaffold `soar_score_api` Package                                                                                                                          | High     | In-Review |
| [009](009-scaffold-ui-package.md)                    | Scaffold `soar_score_ui` Package                                                                                                                           | High     | In-Review |
| [010](010-setup-auth0-identity.md)                   | Auth0 Identity Setup                                                                                                                                       | High     | Open      |
| [011](011-ci-workflow-and-docs.md)                   | GitHub Actions CI Workflow and Onboarding Docs                                                                                                             | High     | In-Review |
| [012](012-playwright-workflow.md)                    | ~~Playwright Integration-Test Workflow Scaffold~~ (replaced by native Flutter/Dart integration tests)                                                      | Medium   | Rejected  |
| [013](013-agentic-coding-rules.md)                   | Agentic Coding Rules (Per-Project AGENTS.md)                                                                                                               | Medium   | Open      |
| [014](014-setup-melos-workspace.md)                  | Melos Workspace at Repository Root                                                                                                                         | High     | Done      |
| [015](015-scaffold-contest-windows-target.md)        | Add Windows target to `soar_score_contest`                                                                                                                 | High     | In-Review |
| [016](016-scaffold-data-postres-package.md)          | Scaffold `soar_score_data_postgres` Package                                                                                                                | High     | In-Review |
| [017](017-sqlite-sync-schema.md)                     | Extract `soar_score_api_handlers` from `soar_score_server` (file name is stale; the original sync-schema spec it carried is orphaned — see its Follow-ups) | High     | In-Review |
| [018](018-embed-soar_score_api_handlers.md)          | Embed `soar_score_api_handlers` in the Windows Target of `soar_score_contest`                                                                              | High     | In-Review |
| [019](019-scaffold-self-score-flutter-app.md)        | Scaffold `soar_score_self_score` (Flutter web)                                                                                                             | High     | Done      |
| [020](020-contest-landing-page-route.md)             | Contest administration landing page (route and shell)                                                                                                      | High     | Done      |
| [021](021-sigin-create-account-stubs.md)             | Sign in and Create account stubs on landing page                                                                                                           | High     | Open      |
| [022](022-continue-offline-desktop.md)               | Continue offline flow on desktop landing page                                                                                                              | High     | Open      |
| [023](023-application-status-area.md)                | Persistent application status area                                                                                                                         | High     | Open      |
| [024](024-landing-page-states.md)                    | Landing page loading, error, and unavailable states                                                                                                        | High     | Open      |
| [025](025-navigation-links-and-external-handling.md) | Navigation links and external-link UX on landing page                                                                                                      | High     | Open      |
| [026](026-accessibility-responsive-locale.md)        | Accessibility, responsive layout, and locale on landing page                                                                                               | High     | Open      |
| [027](027-contest-home-route-shell.md)               | Contest administration home route and shell                                                                                                                | High     | Open      |
| [028](028-contest-list-pagination-empty-state.md)    | Contest list with pagination and empty state                                                                                                               | High     | Open      |
| [029](029-contest-selection-open-actions.md)         | Contest selection and open/continue/view actions                                                                                                           | High     | Open      |
| [030](030-create-contest-navigation.md)              | Create new contest navigation                                                                                                                              | High     | Open      |
| [031](031-contest-delete-delisting.md)               | Delete and delisting contests                                                                                                                              | High     | Open      |
| [032](032-contest-archive-filter.md)                 | Contest archive filter                                                                                                                                     | Medium   | Open      |
| [033](033-home-page-sync-action.md)                  | Sync action on home page                                                                                                                                   | Medium   | Open      |
| [035](035-create-data-models.md)                     | Implement canonical domain models (48 entities)                                                                                                            |
| [036](036-create-drift-schema.md)                    | Implement the Drift schema for the 48-entity model                                                                                                         |
| [037](037-sync-protocol-and-engine.md)               | Synchronization protocol, server service and client engine                                                                                                 |

## Suggested execution order

1. **001** — pin Flutter/Dart/Melos versions; update `plan/implementation-plan.md`.
2. **006** — `soar_score_core` (everything else depends on its types).
3. **007 → 008** — `soar_score_data`, then `soar_score_api` (both build on core).
4. **003** — `soar_score_server` (its `/health` is the contract `soar_score_api`'s example DTO targets).
5. **004, 005, 019** — the Flutter apps (contest, public, self-score): theme baselines and routing skeletons.
   5a. **015** — Windows platform for `soar_score_contest` (reuses 004's app; its CI job lands with 011).
   5b. **017** — extract `soar_score_api_handlers` out of `soar_score_server` (its routing table becomes a shared `buildApiHandler` factory; also needs 016's Postgres repository to wire the deployed server).
   5c. **018** — embed `soar_score_api_handlers` in the Windows target of `soar_score_contest` (needs 007, 008, 015, and 017; the in-process `localhost` server behind the offline build).
6. **009** — `soar_score_ui` (needs both theme baselines to reference).
7. **014** — Melos workspace at repository root (handled after the Dart workspace and projects exist; links projects 003–009 and wires the bulk commands; naming comes from `plan/implementation-plan.md`). ~~002 (NX) is rejected.~~
8. **010** — Auth0 tenant + JWT middleware + Flutter PKCE login.
9. **011** — base CI workflow + root README (needs all projects present and Melos bootstrap working).
10. ~~**012** — Playwright scaffold~~ — rejected; replaced by native Flutter/Dart integration tests.
11. **013** — per-project AGENTS.md files (last; it codifies everything the other tickets established).
12. **020 → 026** — landing page: route and shell, then auth stubs, offline mode, status area, page states, navigation links, accessibility.
13. **027 → 033** — contest administration home: route and shell contest list, selection and opening, create contest, delete/delisting, archive filter, sync action.

## Out of scope (tracked later)

Domain models, the scoring engine, SQLite migrations beyond the in-memory example, real API endpoints/DTOs, offline sync, and all feature work remain future ticket series in this folder (numbering continues after 026).
