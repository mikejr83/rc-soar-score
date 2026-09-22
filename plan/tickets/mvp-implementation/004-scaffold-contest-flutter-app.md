# Ticket 004 — Scaffold `soar_score_contest` (Flutter web)

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

The contest management application is a Flutter app used primarily on laptops/tablets, run as a maximized window (desktop or web), designed to be clear, concise, and aware that it may run disconnected (`plan/implementation-plan.md`, `plan/architecture-requirements/offline-usage.md`). This ticket creates the runnable shell only: routing skeleton, Material 3 theme baseline, and test setup. Offline storage and syncing are later workstreams.

## Work Items

- [ ] Create `apps/soar_score_contest` via `flutter create` (web platform, project name per ticket 002), keep the generated test scaffolding.
- [ ] Add a minimal routing skeleton (e.g. go_router) with two placeholder routes: a home/dashboard route and a second placeholder, demonstrating the navigation construct that will be shared with the public app.
- [ ] Establish the Material 3 `ThemeData` baseline in a dedicated theme file (seed color, scheme, light/dark).
- [ ] Add `project.json` with targets per ticket 002: `pub-get` (flutter pub get), `build` (`flutter build web --no-pub`), `serve` (`flutter run -d chrome --no-pub`), `test` (`flutter test --no-pub`), `analyze` (`flutter analyze --no-pub`).
- [ ] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- [ ] Add one example widget test and one example unit test, both passing.

## Acceptance Criteria

- [ ] `flutter run -d chrome` launches the app and renders the theme and both placeholder routes.
- [ ] `flutter test` and `flutter analyze` pass against `soar_score_contest`.
- [ ] Theme is defined in a single file; no inline `MaterialApp(theme:)` values outside that file.

## Dependencies

- [002-scaffold-nx-workspace.md](002-scaffold-nx-workspace.md)

## Sources

- `plan/implementation-plan.md`
- `plan/architecture-requirements/offline-usage.md`
- `AGENTS.md`
