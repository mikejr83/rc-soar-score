# MVP Implementation — Repository Setup Tickets

Tickets for getting the repository basics in place: toolchain, NX workspace, the three apps and four shared packages, Auth0 identity, CI/CD, and agentic-coding rules. These are *implementation work* tickets (work items with checkboxes), distinct from the decision tickets in `../pre-implementation/`.

## How to use

- Each ticket has **Category**, **Priority**, **Status**, **Context**, **Work Items** (checkboxes), **Acceptance Criteria**, **Dependencies**, and **Sources**.
- Work through dependencies first. A ticket is done when every Work Item and Acceptance Criterion checkbox is ticked and its `Status` is flipped to `Decided` — use `Done` instead for this folder: flip `Status` from `Open` to `Done` when complete.
- Versions are never guessed at execution time: if a pin recorded in ticket 001 is stale, update ticket 001 first, then anything that references it.

## Index

| Ticket | Title | Priority | Status |
| ------ | ----- | -------- | ------ |
| [001](001-setup-toolchain-baseline.md) | Toolchain and Version Baseline | High | Done |
| [002](002-scaffold-nx-workspace.md) | NX Workspace at Repository Root | High | Open |
| [003](003-scaffold-dart-api-app.md) | Scaffold `soar_score_server` (Dart/shelf) | High | Open |
| [004](004-scaffold-contest-flutter-app.md) | Scaffold `soar_score_contest` (Flutter web) | High | Open |
| [005](005-scaffold-public-flutter-app.md) | Scaffold `soar_score_public` (Flutter web) | High | Open |
| [006](006-scaffold-core-package.md) | Scaffold `soar_score_core` Package | High | Open |
| [007](007-scaffold-data-package.md) | Scaffold `soar_score_data` Package | High | Open |
| [008](008-scaffold-api-package.md) | Scaffold `soar_score_api` Package | High | Open |
| [009](009-scaffold-ui-package.md) | Scaffold `soar_score_ui` Package | High | Open |
| [010](010-setup-auth0-identity.md) | Auth0 Identity Setup | High | Open |
| [011](011-ci-workflow-and-docs.md) | GitHub Actions CI Workflow and Onboarding Docs | High | Open |
| [012](012-playwright-workflow.md) | Playwright Integration-Test Workflow Scaffold | Medium | Open |
| [013](013-agentic-coding-rules.md) | Agentic Coding Rules (Per-Project AGENTS.md) | Medium | Open |

## Suggested execution order

1. **001** — pin Node/Flutter/NX/Dart versions; update `plan/implementation-plan.md`.
2. **002** — NX workspace + naming convention decision.
3. **006** — `soar_score_core` (everything else depends on its types).
4. **007 → 008** — `soar_score_data`, then `soar_score_api` (both build on core).
5. **003** — `soar_score_server` (its `/healthz` is the contract `soar_score_api`'s example DTO targets).
6. **004, 005** — the two Flutter apps (theme baselines).
7. **009** — `soar_score_ui` (needs both theme baselines to reference).
8. **010** — Auth0 tenant + JWT middleware + Flutter PKCE login.
9. **011** — base CI workflow + root README (needs all projects present).
10. **012** — Playwright scaffold (can start in parallel with 010–011; needs the apps + API to boot).
11. **013** — per-project AGENTS.md files (last; it codifies everything the other tickets established).

## Out of scope (tracked later)

Domain models, the scoring engine, SQLite migrations beyond the in-memory example, real API endpoints/DTOs, offline sync, and all feature work remain future ticket series in this folder (numbering continues at 014+).
