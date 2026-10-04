# Ticket 019 — Scaffold `soar_score_self_score` (Flutter web)

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

The self-scoring application allows pilots to report scores from their flights. While sharing the Material 3 design language with the other Flutter apps, it is designed primarily for smaller screens (mobile browsers) rather than the large-screen focus of `soar_score_contest`. Per `plan/implementation-plan.md`, it lives in its own Flutter project to enable future native mobile builds (Android first). This ticket creates the runnable shell only: routing skeleton, Material 3 theme baseline, and test setup. Scoring logic, API calls, and participant registration are later workstreams.

## Work Items

- [x] Create `apps/soar_score_self_score` via `flutter create` (web platform, project name per `plan/implementation-plan.md`), keep the generated test scaffolding (generated `test/widget_test.dart`, re-aimed at the real app rather than the stock counter).
- [x] Add a minimal routing skeleton (e.g. go_router) with two placeholder routes: a home/registration route and a second placeholder (e.g. score-entry page), demonstrating the navigation construct.
- [x] Establish the Material 3 `ThemeData` baseline in a dedicated theme file (seed color, scheme, light/dark), with attention to smaller-screen legibility.
- [x] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- [x] Add one example widget test and one example unit test, both passing (widget test in `test/widget_test.dart`; unit test in `test/app_theme_test.dart`).

## Acceptance Criteria

- [x] `flutter run -d chrome` launches the app and renders the theme and both placeholder routes. (Verified on http://localhost:53009)
- [x] `flutter test` and `flutter analyze` pass against `soar_score_self_score` (no analyzer warnings, tests green).
- [x] Theme is defined in a single file; no inline `MaterialApp(theme:)` values outside that file (`lib/theme/app_theme.dart` only; `lib/app.dart` references `AppTheme.*`).

## Files changed

- `apps/soar_score_self_score/` — `flutter create` web scaffold (pubspec.yaml, .gitignore, .metadata, web/, analysis_options.yaml, README.md, generated scaffolding).
- `apps/soar_score_self_score/pubspec.yaml` — description/version aligned with `soar_score_server`/`soar_score_contest` conventions (`0.1.0`); `go_router` added via `flutter pub add go_router` (18.0.1).
- `apps/soar_score_self_score/lib/main.dart` — entry point, runs the self-scoring app.
- `apps/soar_score_self_score/lib/app.dart` — app widget wiring `MaterialApp.router`, title, and the single-file theme.
- `apps/soar_score_self_score/lib/theme/app_theme.dart` — M3 `ThemeData` baseline (`AppTheme.light()`/`AppTheme.dark()`, seed via `ColorScheme.fromSeed`).
- `apps/soar_score_self_score/lib/router.dart` — go_router skeleton: `/` (home/registration) and `/scores` (score-entry placeholder).
- `apps/soar_score_self_score/lib/pages/home_page.dart`, `lib/pages/score_entry_page.dart` — placeholder routes with inter-navigation.
- `apps/soar_score_self_score/test/widget_test.dart` — re-aimed at the real app; exercises both routes and back-navigation.
- `apps/soar_score_self_score/test/app_theme_test.dart` — unit test asserting the Material 3 baseline and light/dark schemes.
- `plan/tickets/mvp-implementation/019-scaffold-self-score-flutter-app.md` — work items and acceptance criteria checked; status → In-Review.
- `plan/tickets/mvp-implementation/README.md` — index row added.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter pin for `flutter create`.
- `plan/implementation-plan.md` — project name and directory convention.
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md) (optional) — reference for routing/theme setup.

## Follow-ups

- Melos workspace linkage (014): this app joins the root Melos workspace when ticket 014 runs; nothing here is Melos-specific.
- Shared navigation/theme tokens may move into `soar_score_ui` (ticket 009) as the self-scoring theme stabilizes.
- Participant registration, score entry, and API integration are deferred to later scoring-engine workstreams.
- Android target (future): `flutter create --platforms=android` once the web shell is complete and shared packages (core, data, api) exist.

## Sources

- `plan/implementation-plan.md`
- `plan/architecture-requirements/offline-usage.md`
- `AGENTS.md`
