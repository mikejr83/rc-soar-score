# Ticket 014 — Melos Workspace at Repository Root

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open
- **Supersedes:** [002-scaffold-nx-workspace.md](002-scaffold-nx-workspace.md) (rejected)

## Context

`plan/implementation-plan.md` defines this repository as a Dart/Flutter monorepo: applications live in `apps/`, shared packages in `packages/` (created when appropriate), and `plan/` remains the stable source of truth for design. The repo is managed by **Melos**, which links the Dart projects together, runs bulk commands (`melos bootstrap`, `melos test`, `melos analyze`), and wires up the path-based inter-package dependencies. This supersedes the rejected NX/Node approach from ticket 002.

`plan/application-plan.md` defines the application set: a contest management app (Flutter, laptop/tablet, must run disconnected), a public viewing site (Flutter web), and a Dart/shelf API layer. The MVP ticket series in this folder scaffolds seven projects: `soar_score_server`, `soar_score_contest`, `soar_score_public` (apps) and `soar_score_core`, `soar_score_data`, `soar_score_api`, `soar_score_ui` (packages).

This work is performed **after the Dart workspace and its projects exist** — i.e. after the scaffold tickets (003–009) have created the `apps/` and `packages/` entries. Melos then links them.

**Project naming:** per `plan/implementation-plan.md`, all Dart project names are snake_case and match their directory names — apps under `apps/` and packages under `packages/` — per the Dart package naming standard. Future projects (e.g. the self-scoring web app, the offline desktop shell described in `plan/application-plan.md`) follow the same pattern. No `AGENTS.md` edit is required: the naming table that previously contradicted the directory layout has been removed.

## Work Items

- [ ] Add a root `melos.yaml` at the repository root that:
  - Declares `packages:` as `apps/**` and `packages/**` so all seven scaffolded projects are discovered.
  - Pins the Melos version and records the Flutter/Dart lines from ticket 001.
  - Defines the shared command scripts that scaffold tickets rely on:
    - `bootstrap` — `melos bootstrap` (resolves all path dependencies; equivalent of the old `pub-get` target).
    - `build` — `melos exec flutter build ...` / `dart compile ...` per project type (record the per-type command).
    - `test` — `melos test` (`melos exec flutter test --no-pub` for Flutter projects, `melos exec dart test --no-pub` for pure-Dart projects).
    - `analyze` — `melos analyze` (`melos exec flutter analyze --no-pub` / `dart analyze --fatal-infos`).
- [ ] Verify `melos bootstrap` resolves every path dependency across the seven projects (the `soar_score_*` packages linking into the apps).
- [ ] Keep `plan/` and `research/` outside the Melos workspace (not matched by `packages:`).
- [ ] Create/ensure the root `.gitignore` covering Dart/Flutter generated artifacts (`.dart_tool/`, `build/`, `.packages`, `pubspec.lock` where appropriate), and coverage output. (Owned here; ticket 010's `.env` entry piggybacks on this file.) Node/NX entries from the rejected ticket 002 are dropped.
- [ ] Confirm Flutter projects are invoked with `--no-pub` via the Melos scripts recorded here (pure-Dart projects use `dart ... --no-pub` where supported).

## Acceptance Criteria

- [ ] `melos bootstrap` succeeds and every path dependency across projects 003–009 resolves.
- [ ] `melos test` runs the test suite for all projects.
- [ ] `melos analyze` runs across all projects and passes.
- [ ] `melos exec -- flutter test --no-pub` / equivalent passes `--no-pub` for Flutter targets.
- [ ] Every project created by tickets 003–009 uses its directory name as its Dart package name, per the convention in `plan/implementation-plan.md`.
- [ ] Root `melos.yaml` is the single source of truth for bulk commands referenced by `AGENTS.md` and the CI ticket (011).

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter/Dart and Melos version pins.
- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) through [009-scaffold-ui-package.md](009-scaffold-ui-package.md) — the Dart workspace and its seven projects must exist before Melos can link them.

## Sources

- `plan/implementation-plan.md`
- `plan/application-plan.md`
- `AGENTS.md`
- `002-scaffold-nx-workspace.md` (naming convention carried over; NX/Node work rejected)
