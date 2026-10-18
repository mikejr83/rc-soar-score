# Public Site Agent Guide

Public-facing web site: project landing page, documentation, and contest results.

## Structure

- `lib/main.dart` — entry point; `lib/app.dart` — `MaterialApp.router` with `PublicAppTheme` light and dark (follows system mode); `lib/router.dart` — go_router routes, all under one `ShellRoute`
- `lib/pages/site/` — landing page, documentation, help, not-found (project pages)
- `lib/pages/results/` — contest results browsing (dense tabular layouts)
- `lib/widgets/` — local reusable widgets, including the site shell (`site_shell.dart`)
- `lib/services/` — non-widget helpers (for example `external_url/`, the web-only external link opener with a VM stub)

## Boundaries

- **Must not write contest data**. Read-only access via `soar_score_api`. Results pages must never expose write endpoints or forms.
- Depends on: `soar_score_core`, `soar_score_api`, `soar_score_ui`
- Routing constructs shared with `soar_score_contest` via `soar_score_ui`.

## Design Notes

- Report-dense layouts may depart from strict Material 3 when tabular data requires it (see `plan/implementation-plan.md`).
- Public site is NOT behind auth middleware (see ticket 010 decision). Results are read-only to everyone.

## Testing

- Widget tests: `flutter test`
- Integration tests: `flutter test integration_test/`
