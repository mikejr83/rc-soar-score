# Contest App Agent Guide

Contest management application for directors, pilots, and helpers. Runs on web and Windows (embedded offline).

## Structure

- `lib/main.dart` — entry point
- `lib/features/` — page widgets by domain: contests, pilots, score-entry, results
- `lib/server/` — Windows-only embedded offline server logic
- `lib/widgets/` — local reusable widgets (not shared with public app)

## Boundaries

- **Must not do direct database access**. All data access goes through `soar_score_api` client (which talks to `soar_score_api_handlers`, which uses `soar_score_data` backed by SQLite in the native app or by PostgreSQL on the server; the web build has no local database and calls the remote API).
- Depends on: `soar_score_core`, `soar_score_data`, `soar_score_api`, `soar_score_sync`, `soar_score_ui`
- `soar_score_sync` is imported only by `lib/platform/native_sync.dart` and `native_bootstrap.dart`, so the web build contains no sync engine (`test/platform/web_closure_test.dart` checks it). Screens reach sync state through `AppBootstrap`, never the package.
- The Material themes and shared color tokens live in `soar_score_ui` (`theme/app_theme.dart`): `ContestAppTheme`, `PublicAppTheme`, `SelfScoreAppTheme`, `AppColors`, `AppStatusColors`.

## Design Notes

- Offline-aware: UI must not assume connectivity (see `plan/architecture-requirements/offline-usage.md`). Show pending-changes state, provide manual sync trigger.
- The web build stores no contest data in the browser (IndexedDB is limited to preferences and front-end functionality). The native build syncs on connect, then writes locally first and immediately through the remote API.
- Routing constructs are shared with `soar_score_public` via `soar_score_ui`.
- Mobile-first responsive layouts (see `plan/architecture-requirements/responsive-design.md`).

## Testing

- Widget tests: `flutter test`
- Integration (E2E) tests: `scripts/e2e.ps1` (or `scripts/e2e.sh`) runs `integration_test/` against the real app on the demo database, recreated per run. Local only, not in CI. Windows by default; `-Device chrome` needs the web bootstrap, which has no offline entry yet.
- Platform-specific tests: `flutter test integration_test/platform/`
