# Ticket 005 — Scaffold `soar_score_public` (Flutter web)

- **Category:** Scaffold
- **Priority:** High
- **Status:** in-review

## Context

The public web site presents both the project site (landing page, documentation, help) and dense, tabular contest results. Departure from strict Material 3 is allowed where report-like layouts need it (`plan/implementation-plan.md`). This ticket creates the runnable shell: app structure with separate areas for the site pages vs. results pages, and test setup.

## Work Items

- [x] Create `apps/soar_score_public` via `flutter create` (web platform, project name per `plan/implementation-plan.md`).
- [x] Add a minimal routing skeleton with distinct route groups: site routes (landing, docs placeholder, help placeholder) and results routes (placeholder results listing), so the later tabular/report UI has a home.
- [x] Establish the Material 3 `ThemeData` baseline in a dedicated theme file, consistent with the contest app baseline (same seed, independent theme file — the two apps keep separate themes).
- [x] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- [x] Add one example widget test (landing route) and one example unit test, both passing.

## Acceptance Criteria

- [x] `flutter run -d chrome` launches the app; site placeholder routes and results placeholder route render.
- [x] `flutter test` and `flutter analyze` pass against `soar_score_public`.
- [x] Route groups make the site-vs-results split visible in the router definitions.

## Files changed

- `apps/soar_score_public/` — new Flutter web app created via `flutter create --platforms=web` (Flutter 3.47.4 stable).
- `apps/soar_score_public/pubspec.yaml` — description/version set; `go_router: ^18.0.1` added.
- `apps/soar_score_public/lib/main.dart` — runs `SoarScorePublicApp`.
- `apps/soar_score_public/lib/app.dart` — `MaterialApp.router` with themes from the dedicated theme file.
- `apps/soar_score_public/lib/router.dart` — `buildAppRouter()` with commented route groups: site routes (`/`, `/docs`, `/help`) and results routes (`/results`).
- `apps/soar_score_public/lib/theme/app_theme.dart` — independent Material 3 `ThemeData` baseline, same seed as the contest app (`0xFF006399`).
- `apps/soar_score_public/lib/pages/site/landing_page.dart`, `lib/pages/site/docs_page.dart`, `lib/pages/site/help_page.dart` — site placeholder pages.
- `apps/soar_score_public/lib/pages/results/results_page.dart` — results placeholder page.
- `apps/soar_score_public/test/widget_test.dart` — widget test: landing route renders and navigates through docs, help, and results placeholders.
- `apps/soar_score_public/test/app_theme_test.dart` — unit test: light/dark themes are Material 3, seed-based, with a lighter/lighter-than check on surfaces (mirrors contest app test shape).
- `plan/tickets/mvp-implementation/005-scaffold-public-flutter-app.md` — status and checks updated for this review.

## Acceptance notes

- All acceptance criteria satisfied. `flutter run -d chrome` was verified to launch (debug service connected; app started from `main`), then stopped. The widget test additionally exercises the placeholder routes directly.

## Follow-ups

- Registering the app in the Melos workspace (root `pubspec.yaml` `workspace:`/`melos:` keys) is owned by ticket 014, not done here.
- Navigation bar/header linking the site-vs-results areas in real UI (per `plan/ui/public-site/` docs) is out of scope for this skeleton; the router groups are already in place for it.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter pin for `flutter create`.
- `plan/implementation-plan.md` — project name and directory convention.

## Sources

- `plan/implementation-plan.md`
- `plan/ui/public-site/README.md`
- `AGENTS.md`
