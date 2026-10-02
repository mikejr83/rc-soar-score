# Ticket 014 — Melos Workspace at Repository Root

- **Category:** Scaffold
- **Priority:** High
- **Status:** Done
- **Supersedes:** [002-scaffold-nx-workspace.md](002-scaffold-nx-workspace.md) (rejected)

## Context

`plan/implementation-plan.md` defines this repository as a Dart/Flutter monorepo: applications live in `apps/`, shared packages in `packages/` (created when appropriate), and `plan/` remains the stable source of truth for design. The repo is managed by **Melos**, which links the Dart projects together, runs bulk commands (`melos bootstrap`, `melos test`, `melos analyze`), and wires up the path-based inter-package dependencies. This supersedes the rejected NX/Node approach from ticket 002.

`plan/application-plan.md` defines the application set: a contest management app (Flutter, laptop/tablet, must run disconnected), a public viewing site (Flutter web), and a Dart/shelf API layer. The MVP ticket series in this folder scaffolds seven projects: `soar_score_server`, `soar_score_contest`, `soar_score_public` (apps) and `soar_score_core`, `soar_score_data`, `soar_score_api`, `soar_score_ui` (packages).

This work is performed **after the Dart workspace and its projects exist** — i.e. after the scaffold tickets (003–009) have created the `apps/` and `packages/` entries. Melos then links them.

**Project naming:** per `plan/implementation-plan.md`, all Dart project names are snake_case and match their directory names — apps under `apps/` and packages under `packages/` — per the Dart package naming standard. Future projects (e.g. the self-scoring web app, the offline desktop shell described in `plan/application-plan.md`) follow the same pattern. No `AGENTS.md` edit is required: the naming table that previously contradicted the directory layout has been removed.

## Work Items

- [x] Set up the repo as a **Pub Workspace** per <https://dart.dev/tools/pub/workspaces> and put the Melos configuration in the root `pubspec.yaml` (Melos 8 dropped the standalone `melos.yaml`; config now lives under the `melos:` key — reconciled per ticket 001's follow-up):
  - Declares `workspace:` as `apps/**` and `packages/**` (glob patterns, supported since Dart 3.11) so all seven scaffolded projects are discovered; every member `pubspec.yaml` carries `resolution: workspace`.
  - Pins the Melos line from ticket 001 — `dev_dependencies: melos: ^8.9.0` (Melos 8.x; the global install switches to the workspace's version) — and records the Flutter/Dart lines in the root `environment:` (`sdk: ^3.13.3`, Flutter 3.47.x per ticket 001).
  - Defines the shared command scripts that scaffold tickets rely on:
    - `bootstrap` — `melos bootstrap` (shared workspace resolution; resolves all path dependencies; equivalent of the old `pub-get` target).
    - `build` — per project type: `melos run build` runs `flutter build web --no-pub` for the Flutter apps under `category: apps` and `dart compile exe lib/main.dart -o build/cli/$MELOS_PACKAGE_NAME.exe` for the pure-Dart apps (recorded here).
    - `test` — `melos test`: `flutter test --no-pub` for Flutter projects, `dart test` for pure-Dart projects (the `--no-pub` config lives in `command.test.noPub`); `dart test` has no `--no-pub` flag.
    - `analyze` — `melos analyze`: `flutter analyze --no-pub --fatal-infos` for Flutter projects, `dart analyze --fatal-infos` for pure-Dart projects (`command.analyze.fatalInfos`/`noPub`).
- [x] Verify `melos bootstrap` resolves every path dependency across the seven projects (the `soar_score_*` packages linking into the apps): `melos bootstrap` reports "7 packages bootstrapped"; shared resolution uses a single root `pubspec.lock` and root `.dart_tool/package_config.json`.
- [x] Keep `plan/` and `research/` outside the Melos workspace (not matched by `workspace:`; `melos list` shows exactly the seven projects).
- [x] Create/ensure the root `.gitignore` covering Dart/Flutter generated artifacts (`.dart_tool/`, `build/`, `.packages`, `pubspec.lock` in each member is deleted by `pub get` in favor of the root lock, which is committed; `pubspec_overrides.yaml`, coverage output, and the Melos-generated IDE files). (Owned here; ticket 010's `.env` entry piggybacks on this file.) Node/NX entries from the rejected ticket 002 are dropped.
- [x] Confirm Flutter projects are invoked with `--no-pub` via the Melos scripts recorded here (`command.analyze.noPub`/`command.test.noPub` and `--no-pub` on `flutter build web`); pure-Dart projects use `dart ...` — `dart test`/`dart analyze` never run `pub get`, and `dart compile exe` has no `--no-pub` flag.

## Acceptance Criteria

- [x] `melos bootstrap` succeeds and every path dependency across projects 003–009 resolves (single shared resolution, root `pubspec.lock` + root `.dart_tool/package_config.json`; member locks and member `package_config.json` files removed).
- [x] `melos test` runs the test suite for all projects (3 Flutter + 4 pure-Dart, all passing).
- [x] `melos analyze` runs across all projects and passes (0 issues in all seven).
- [x] `melos exec -- flutter test --no-pub` / equivalent passes `--no-pub` for Flutter targets (`flutter build web --no-pub`, configured `--no-pub` on `flutter test`/`flutter analyze`).
- [x] Every project created by tickets 003–009 uses its directory name as its Dart package name, per the convention in `plan/implementation-plan.md` (`soar_score_server`, `soar_score_contest`, `soar_score_public`, `soar_score_core`, `soar_score_data_sqlite`, `soar_score_api`, `soar_score_ui`).
- [x] The root `pubspec.yaml` (`workspace:` + `melos:` sections) is the single source of truth for bulk commands referenced by `AGENTS.md` and the CI ticket (011).

## Follow-ups

- VS Code integration (separate from this ticket's scope): `.vscode/tasks.json` provides the four bulk commands from the root `pubspec.yaml` Melos scripts and `melos run build` via shell tasks — the `blaugold.melos-code` extension's native `type: "melos"` tasks resolve only _defined_ scripts (Melos 8: `melos run` rejects built-in names) and its task/CodeLens providers load only a standalone `melos.yaml`, which Melos 8 dropped in favor of `pubspec.yaml`; extension install is still recommended for its `Melos: Bootstrap` / `Melos: Run script` commands (its config-aware features are inert under Melos 8). `.vscode/launch.json` adds a `Server + Contest (Web)` compound. Requires `C:\Users\mikej\AppData\Local\Pub\Cache\bin` on `PATH` for bare `melos` (already set on this machine; `dart run melos` always works).

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter/Dart and Melos version pins.
- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) through [009-scaffold-ui-package.md](009-scaffold-ui-package.md) — the Dart workspace and its seven projects must exist before Melos can link them.

## Sources

- `plan/implementation-plan.md`
- `plan/application-plan.md`
- `AGENTS.md`
- `002-scaffold-nx-workspace.md` (naming convention carried over; NX/Node work rejected)
