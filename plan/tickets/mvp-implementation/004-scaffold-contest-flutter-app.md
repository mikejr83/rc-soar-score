# Ticket 004 — Scaffold `soar_score_contest` (Flutter web)

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

The contest management application is a Flutter app used primarily on laptops/tablets, run as a maximized window (desktop or web), designed to be clear, concise, and aware that it may run disconnected (`plan/implementation-plan.md`, `plan/architecture-requirements/offline-usage.md`). This ticket creates the runnable shell only: routing skeleton, Material 3 theme baseline, and test setup. Offline storage and syncing are later workstreams.

## Work Items

- [x] Create `apps/soar_score_contest` via `flutter create` (web platform, project name per `plan/implementation-plan.md`), keep the generated test scaffolding (generated `test/widget_test.dart`, re-aimed at the real app rather than the stock counter).
- [x] Add a minimal routing skeleton (e.g. go_router) with two placeholder routes: a home/dashboard route and a second placeholder, demonstrating the navigation construct that will be shared with the public app.
- [x] Establish the Material 3 `ThemeData` baseline in a dedicated theme file (seed color, scheme, light/dark).
- [x] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- [x] Add one example widget test and one example unit test, both passing (widget test in `test/widget_test.dart`; unit test in `test/app_theme_test.dart`).

## Acceptance Criteria

- [x] `flutter run -d chrome` launches the app and renders the theme and both placeholder routes (verified 2026-09-22: app served on `http://127.0.0.1:8091`, HTTP 200; widget tests cover both routes).
- [x] `flutter test` and `flutter analyze` pass against `soar_score_contest` (4/4 tests, no analyzer issues, 2026-09-22).
- [x] Theme is defined in a single file; no inline `MaterialApp(theme:)` values outside that file (`lib/theme/app_theme.dart` only; `lib/app.dart` references `AppTheme.*`).

## Files changed

- `apps/soar_score_contest/` — `flutter create` web scaffold (pubspec.yaml, .gitignore, .metadata, web/, analysis_options.yaml, README.md, generated scaffolding).
- `apps/soar_score_contest/pubspec.yaml` — description/version aligned with `soar_score_server` conventions (`0.1.0`); `go_router` added via `flutter pub add go_router` (18.0.1).
- `apps/soar_score_contest/lib/main.dart` — entry point, runs `SoarScoreContestApp`.
- `apps/soar_score_contest/lib/app.dart` — `SoarScoreContestApp` wiring `MaterialApp.router`, title, and the single-file theme.
- `apps/soar_score_contest/lib/theme/app_theme.dart` — M3 `ThemeData` baseline (`AppTheme.light()`/`AppTheme.dark()`, seed via `ColorScheme.fromSeed`).
- `apps/soar_score_contest/lib/router.dart` — go_router skeleton: `/` (home/dashboard) and `/contests` (second placeholder).
- `apps/soar_score_contest/lib/pages/home_page.dart`, `lib/pages/contests_page.dart` — placeholder routes with inter-navigation.
- `apps/soar_score_contest/test/widget_test.dart` — re-aimed at the real app; exercises both routes and back-navigation.
- `apps/soar_score_contest/test/app_theme_test.dart` — unit test asserting the Material 3 baseline and light/dark schemes.
- `plan/tickets/mvp-implementation/004-scaffold-contest-flutter-app.md` — work items and acceptance criteria checked; status → In-Review.

## Follow-ups

- Melos workspace linkage (014): this app joins the root Melos workspace when ticket 014 runs; nothing here is Melos-specific.
- Shared navigation/theme tokens move into `soar_score_ui` (ticket 009), which references both theme baselines; this app keeps its own local baseline until then.
- Offline awareness (connection/ready state UI per `plan/architecture-requirements/offline-usage.md`) is deferred to the data/sync workstreams.
- `flutter run -d chrome` verified via the served HTTP 200 and the debug-service connection; the theme/routes themselves are asserted in `test/widget_test.dart` since the CLI cannot drive the browser UI headlessly.
- Windows target added by [015](015-scaffold-contest-windows-target.md) (`flutter create --platforms=windows`; offline frame UI still deferred).

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter pin for `flutter create`.
- `plan/implementation-plan.md` — project name and directory convention.

## Sources

- `plan/implementation-plan.md`
- `plan/architecture-requirements/offline-usage.md`
- `AGENTS.md`
