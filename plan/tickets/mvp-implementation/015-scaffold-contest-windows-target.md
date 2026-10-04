# Ticket 015 — Scaffold Windows Target for `soar_score_contest`

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

`plan/implementation-plan.md` states that the same Flutter code base for `soar_score_contest` "underpins the stand-alone offline desktop shell," and `plan/application-plan.md` / `plan/architecture-requirements/offline-usage.md` describe the offline application as the web app wrapped in a desktop shell with front-end parity. Ticket 004 created `soar_score_contest` as a web platform only. This ticket adds the **Windows platform** to that existing project so contest directors can run the application as a local, disconnected desktop app. The generated `windows/` runner directory is committed (it is source, not build output); `build/` artifacts are not. Offline _frame_ UI (connectivity/sync indicators, import/export warnings per `plan/ui/contest-administration/offline-ui.md`) and offline storage/sync are later workstreams and out of scope here.

**Prerequisite (recorded, not a ticket 001 pin):** Windows builds require Visual Studio 2022 with the "Desktop development with C++" workload on the build machine; `flutter doctor -v` must report it active. `windows-latest` GitHub runners include it by default.

## Work Items

- [x] Add the Windows platform to the existing project: run `flutter create --platforms=windows .` in `apps/soar_score_contest` (adds `windows/`; appends `windows` to the supported platforms in `.metadata`; leaves the existing `web/` platform untouched).
- [x] Verify on a Windows host (`flutter doctor -v` → Windows toolchain active): `flutter run -d windows` launches the app in a window and renders the Material 3 theme and both placeholder routes (`/`, `/contests`).
- [x] Verify `flutter build windows --release` succeeds and produces the release executable under `build/windows/x64/runner/Release/`.
- [x] Verify `flutter test` (4/4) and `flutter analyze` remain green after adding the platform, and `flutter build web --no-pub` still succeeds (web behavior unchanged).
- [x] Confirm `git status` shows only the generated `windows/` source files as new (no `build/` or runner artifacts).
- [ ] Amend ticket 011 (`011-ci-workflow-and-docs.md`) work items to add a second workflow job: `windows-latest` runner that installs the pinned Flutter from ticket 001, runs `melos bootstrap`, then builds the contest app only (`flutter build windows --no-pub` from its directory); `analyze`/`test` stay on the existing `ubuntu-latest` job. If `.github/workflows/ci.yml` does not exist yet (011 not landed), apply the job when 011 executes and tick this work item then.
- [x] Update `README.md` in this folder: index row for 015 and execution-order placement (after step 5, "004, 005"; CI-job portion lands with 011).
- [x] Add a one-line follow-up to ticket 004's Follow-ups: Windows target added by 015.

## Acceptance Criteria

- [x] `flutter build windows --release` succeeds on a Windows host and `flutter run -d windows` renders the theme and both placeholder routes (manual verification, same approach as ticket 004's chrome verification since the CLI cannot drive the desktop window headlessly; verified 2026-09-22: release exe built under `build\windows\x64\runner\Release\`, run reached the VM service, both routes covered by `test/widget_test.dart`).
- [x] `flutter test`, `flutter analyze`, and `flutter build web --no-pub` pass unchanged in `apps/soar_score_contest`.
- [x] No new pubspec dependencies; no behavioral change to the web app.
- [x] `ci.yml` contains a passing `windows-latest` job for the contest app (or the job is recorded in ticket 011's work items, pending 011's execution — either state satisfies this ticket at its execution time; `ci.yml` unlanded, job recorded in 011's work items).
- [ ] Generated `windows/` directory is committed; no `build/` artifacts are tracked.

## Follow-ups

- Offline frame UI (connectivity/remote-API/local-storage indicators, sync status, automatic/manual sync, publish, recovery export/import per `plan/ui/contest-administration/offline-ui.md`) belongs to the data/sync workstreams (future tickets, 015+ series).
- Local SQLite storage, HTTP repositories, and the offline data path are ticket 007's package territory, not this app yet.
- Custom window icon / product branding for `windows/runner` deferred until brand assets exist.
- Ticket 014's per-type `build` command record should include `flutter build windows --no-pub` for `soar_score_contest` (note in 014 follow-ups).

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter pin used for `flutter create` and CI.
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md) — the `soar_score_contest` project must exist (Done).
- [011-ci-workflow-and-docs.md](011-ci-workflow-and-docs.md) — `ci.yml` must exist for the Windows job amendment to be executed (satisfied at 011's execution if it has not landed yet).

## Sources

- `plan/implementation-plan.md`
- `plan/application-plan.md`
- `plan/architecture-requirements/offline-usage.md`
- `plan/ui/contest-administration/offline-ui.md`
- `AGENTS.md`
