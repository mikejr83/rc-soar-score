# Ticket 011 — GitHub Actions CI Workflow and Developer Onboarding Docs

- **Category:** CI/CD
- **Priority:** High
- **Status:** Open

## Context

`plan/implementation-plan.md` requires GitHub workflows for building and testing the application. This ticket creates the base workflow covering the pins from ticket 001 (Node, Flutter — replacing the stale Node 20 / Flutter 3.24.0 references) plus a root `README.md` so a fresh clone has one place for setup/run/test instructions. The Playwright workflow is a separate ticket (012).

## Work Items

- [ ] Create `.github/workflows/ci.yml`:
  - Triggers: push and pull_request to `main` and `develop`.
  - Runner: `ubuntu-latest`, single job (splitting into per-project jobs is an optimization, not a requirement).
  - Steps: check out → setup Node (pinned version from ticket 001, with cache) → install NX/npm deps → install exact Flutter pin from ticket 001 → `npx nx run-many --target=pub-get --all` → `npx nx run-many --target=analyze --all` → `npx nx run-many --target=test --all` → `npx nx run-many --target=build --all`.
  - Fail the run on any analyze or test failure.
- [ ] Add a root `README.md` covering: project overview, prerequisites (Node, Flutter versions from ticket 001), install/serve/test/lint commands (mirroring `AGENTS.md`'s script table), and a pointer to `plan/INDEX.md`.
- [ ] Verify the workflow runs green end-to-end on an initial commit after the scaffold tickets land.

## Acceptance Criteria

- [ ] `ci.yml` references the exact pinned Node and Flutter versions from ticket 001 (no `latest`, no stale 3.24.0/Node 20).
- [ ] Workflow triggers on both branches and on PRs.
- [ ] All four `run-many` targets complete in the workflow.
- [ ] Root `README.md` commands match the real `package.json` scripts.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md)
- [002-scaffold-nx-workspace.md](002-scaffold-nx-workspace.md)
- [003](003-scaffold-dart-api-app.md) through [009](009-scaffold-ui-package.md) — projects must exist for the workflow to exercise.

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
