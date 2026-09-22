# MVP Implementation — Repository Setup Tickets

Tickets for getting the repository basics in place: toolchain, Melos workspace, the three apps and four shared packages, Auth0 identity, CI/CD, and agentic-coding rules. These are *implementation work* tickets (work items with checkboxes), distinct from the decision tickets in `../pre-implementation/`.

## How to use

- Each ticket has **Category**, **Priority**, **Status**, **Context**, **Work Items** (checkboxes), **Acceptance Criteria**, **Dependencies**, and **Sources**.
- Work through dependencies first. A ticket is done when every Work Item and Acceptance Criterion checkbox is ticked and its `Status` is flipped to `Decided` — use `Done` instead for this folder: flip `Status` from `Open` to `Done` when complete.
- Tickets superseded by a newer approach are marked `Rejected` (see 002 — NX, and 012 — Playwright, both replaced by native Dart/Flutter tooling with Melos for monorepo management).
- Versions are never guessed at execution time: if a pin recorded in ticket 001 is stale, update ticket 001 first, then anything that references it.

## Index

| Ticket | Title | Priority | Status |
| ------ | ----- | -------- | ------ |
| [001](001-setup-toolchain-baseline.md) | Toolchain and Version Baseline | High | Done |
| [002](002-scaffold-nx-workspace.md) | ~~NX Workspace at Repository Root~~ (replaced by 014) | High | Rejected |
| [003](003-scaffold-dart-api-app.md) | Scaffold `soar_score_server` (Dart/shelf) | High | Open |
| [004](004-scaffold-contest-flutter-app.md) | Scaffold `soar_score_contest` (Flutter web) | High | In-Review |
| [005](005-scaffold-public-flutter-app.md) | Scaffold `soar_score_public` (Flutter web) | High | Open |
| [006](006-scaffold-core-package.md) | Scaffold `soar_score_core` Package | High | Open |
| [007](007-scaffold-data-package.md) | Scaffold `soar_score_data` Package | High | Open |
| [008](008-scaffold-api-package.md) | Scaffold `soar_score_api` Package | High | Open |
| [009](009-scaffold-ui-package.md) | Scaffold `soar_score_ui` Package | High | Open |
| [010](010-setup-auth0-identity.md) | Auth0 Identity Setup | High | Open |
| [011](011-ci-workflow-and-docs.md) | GitHub Actions CI Workflow and Onboarding Docs | High | Open |
| [012](012-playwright-workflow.md) | ~~Playwright Integration-Test Workflow Scaffold~~ (replaced by native Flutter/Dart integration tests) | Medium | Rejected |
| [013](013-agentic-coding-rules.md) | Agentic Coding Rules (Per-Project AGENTS.md) | Medium | Open |
| [014](014-setup-melos-workspace.md) | Melos Workspace at Repository Root | High | Open |

## Suggested execution order

1. **001** — pin Flutter/Dart/Melos versions; update `plan/implementation-plan.md`.
2. **006** — `soar_score_core` (everything else depends on its types).
3. **007 → 008** — `soar_score_data`, then `soar_score_api` (both build on core).
4. **003** — `soar_score_server` (its `/healthz` is the contract `soar_score_api`'s example DTO targets).
5. **004, 005** — the two Flutter apps (theme baselines).
6. **009** — `soar_score_ui` (needs both theme baselines to reference).
7. **014** — Melos workspace at repository root (handled after the Dart workspace and projects exist; links projects 003–009 and wires the bulk commands; naming comes from `plan/implementation-plan.md`). ~~002 (NX) is rejected.~~
8. **010** — Auth0 tenant + JWT middleware + Flutter PKCE login.
9. **011** — base CI workflow + root README (needs all projects present and Melos bootstrap working).
10. ~~**012** — Playwright scaffold~~ — rejected; replaced by native Flutter/Dart integration tests.
11. **013** — per-project AGENTS.md files (last; it codifies everything the other tickets established).

## Out of scope (tracked later)

Domain models, the scoring engine, SQLite migrations beyond the in-memory example, real API endpoints/DTOs, offline sync, and all feature work remain future ticket series in this folder (numbering continues at 015+).
