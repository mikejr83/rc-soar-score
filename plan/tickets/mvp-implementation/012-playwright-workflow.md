# Ticket 012 — Playwright Integration-Test Workflow Scaffold — REJECTED

- **Category:** CI/CD
- **Priority:** Medium
- **Status:** Rejected (replaced by native Dart/Flutter integration tests)

## Context

> **REJECTED / INVALID — superseded.** This ticket is no longer actionable. Playwright is a Node.js tool and the repository has moved away from Node/NX to native Dart and Flutter tooling with Melos for monorepo management. Integrated testing of the client + API layers will instead be done with **native Dart/Flutter integration tests** (Flutter `integration_test` for the web targets, plus HTTP-based `dart test` suites against `soar_score_server`), using the CI workflow from ticket 011. The requirement "each client application should be tested" still stands; only the mechanism changes. The original text below is kept for history. Do not act on it.

## Context (original)

`plan/implementation-plan.md` requires: "Each of the client application should be tested via Playwright" for integrated testing of the client + API layers, and "a workflow for performing manual integration testing using Playwright is also to be included." Real e2e scenarios need the apps and API to have features; this ticket scaffolds the tooling and workflow now so a first e2e test (against the health endpoint + app shell) lands as soon as features exist.

## Work Items (original — superseded)

- [ ] Create a `playwright/` folder at the repo root containing:
  - `package.json` with `@playwright/test`.
  - `playwright.config.ts` with projects for the two Flutter web targets (contest, public), and a base URL configurable via env var.
  - `fixtures/` for a fixture that starts (or assumes already running) the `soar-score-api` server and the Flutter web build/dev server under test.
  - One example spec: navigate to the contest app shell, assert the dashboard route renders, and call `GET /healthz` from the page context.
- [ ] Create `.github/workflows/playwright.yml`:
  - Trigger: PRs/pushes to `main` and `develop` (or, per the plan's "manual integration testing" intent, a workflow_dispatch trigger — pick one and record the choice; recommend both: manual dispatch plus PR gate once tests grow).
  - Steps: setup Node + Flutter (pins from ticket 001) → pub-get → build the Flutter web targets → serve them (static server or `flutter run -d chrome` headless equivalent) → run the API server in the background → run `npx playwright test` → attach trace/video artifacts on failure.
- [ ] Keep this separate from `ci.yml` so the e2e gate does not block unit-level CI.

## Acceptance Criteria (original — superseded)

- [ ] `npx playwright test` runs the example spec locally against the scaffolded apps + API.
- [ ] `playwright.yml` runs the same flow in GitHub Actions and uploads artifacts on failure.
- [ ] The fixture isolates ports/processes cleanly (no port collisions with the API's default 8080 when running both).

## Dependencies

- [011-ci-workflow-and-docs.md](011-ci-workflow-and-docs.md) — pins and runner environment conventions.
- [003](003-scaffold-dart-api-app.md), [004](004-scaffold-contest-flutter-app.md), [005](005-scaffold-public-flutter-app.md) — targets under test.

## Replacement note

Native integration testing will be scaffolded within the existing projects when feature work lands: Flutter `integration_test` for `soar_score_contest` and `soar_score_public` (web driver), and `dart test` HTTP suites against `soar_score_server`. The GitHub Actions workflow for manual/integration runs folds into ticket 011's conventions (`melos` + pinned toolchain). Track the concrete integration-test scaffolding in a future ticket (015+).

## Sources

- `plan/implementation-plan.md`
