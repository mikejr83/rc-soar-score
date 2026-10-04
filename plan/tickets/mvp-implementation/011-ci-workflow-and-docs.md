# Ticket 011 — GitHub Actions CI Workflow and Developer Onboarding Docs

- **Category:** CI/CD
- **Priority:** High
- **Status:** In-Review

## Context

`plan/implementation-plan.md` requires GitHub workflows for building and testing the application. This ticket creates the base workflow covering the pins from ticket 001 (Dart/Flutter and Melos — replacing the stale Node 20 / Flutter 3.24.0 and NX references; Node is no longer part of the toolchain) plus a root `README.md` so a fresh clone has one place for setup/run/test instructions. The integration-test workflow was ticket 012 (rejected — replaced by native Flutter/Dart integration tests); CI here covers analyze/test/build via Melos.

## Work Items

- [x] Create `.github/workflows/ci.yml`:
  - Triggers: push and pull_request to `main` and `develop`.
  - Runner: `ubuntu-latest`, single job for analyze/test/build (splitting into per-project jobs is an optimization, not a requirement). Plus a second `windows-latest` job (per [015](015-scaffold-contest-windows-target.md)): install the exact Flutter pin from ticket 001 → `melos bootstrap` → `flutter build windows --no-pub` for `apps/soar_score_contest` only (`flutter build windows` cannot run on Linux runners; analyze/test remain on the `ubuntu-latest` job).
  - Steps: check out → install exact Flutter pin from ticket 001 (`subosito/flutter-action` or equivalent, cache on) → install/dart pub global activate Melos (pinned from ticket 001) → `melos bootstrap` → `melos analyze` → `melos test` → per-project build (`flutter build web --no-pub` for the two Flutter apps, `dart compile` for the API, per ticket 014).
  - Fail the run on any analyze or test failure.
- [x] Add a root `README.md` covering: project overview, prerequisites (Flutter/Dart and Melos versions from ticket 001), install/serve/test/lint commands (mirroring `AGENTS.md`'s script table, i.e. `melos bootstrap`, `melos analyze`, `melos test`), and a pointer to `plan/INDEX.md`.
- [ ] Verify the workflow runs green end-to-end on an initial commit after the scaffold tickets land.

## Acceptance Criteria

- [ ] `ci.yml` references the exact pinned Dart/Flutter and Melos versions from ticket 001 (no `latest`, no stale 3.24.0/Node 20, and no NX/Node steps).
- [ ] Workflow triggers on both branches and on PRs.
- [ ] `melos bootstrap`, `melos analyze`, `melos test`, and the per-project build steps all complete in the workflow.
- [ ] Root `README.md` commands match the real Melos commands from `AGENTS.md`.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md)
- [014-setup-melos-workspace.md](014-setup-melos-workspace.md) — bulk commands must be defined (replaces rejected 002).
- [003](003-scaffold-dart-api-app.md) through [009](009-scaffold-ui-package.md) — projects must exist for the workflow to exercise.

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
