# Ticket 001 — Toolchain and Version Baseline

- **Category:** Setup
- **Priority:** High
- **Status:** Open

## Context

`plan/implementation-plan.md` references Node 20 and Flutter 3.24.0 for CI. Those pins are stale and there is currently no single source of truth for versioning in the repository. Every other setup ticket (workspace, apps, packages, CI) depends on agreeing on the toolchain versions first.

## Work Items

- [ ] Identify the current stable versions to pin:
  - Node.js: current active LTS (Node 24 as of September 2026 — verify).
  - Flutter: current stable channel — record the exact version here at execution time (`flutter --version`).
  - NX: current stable major — record version here at execution time.
  - Dart: comes bundled with Flutter; note the bundled Dart version.
- [ ] Add `node_modules` / Dart / Flutter / NX generated artifacts to a root `.gitignore` (`.dart_tool/`, `build/`, `.dart_tool/`, `.packages`, `.nx/cache/`, `node_modules/`, coverage output).
- [ ] Add a root `.nvmrc` with the pinned Node version and an `engines` field in the root `package.json`.
- [ ] Update `plan/implementation-plan.md` and any workflow file created later to reference the actual pinned versions (CI must not drift from the pins recorded here).

## Acceptance Criteria

- [ ] Exact pinned versions (Node, Flutter, NX, Dart) are recorded in this ticket and in the repo (`.nvmrc`, `engines`, CI config).
- [ ] `plan/implementation-plan.md` no longer references stale Node 20 / Flutter 3.24.0.
- [ ] Root `.gitignore` covers Dart, Flutter, and NX build artifacts.

## Dependencies

- None (first ticket in the series).

## Sources

- `plan/implementation-plan.md`
- `AGENTS.md`
