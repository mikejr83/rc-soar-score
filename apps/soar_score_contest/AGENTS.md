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
- Integration (E2E) tests: `scripts/e2e.ps1` (or `scripts/e2e.sh`) runs `integration_test/` against the real app on the demo database, recreated per run. Local only, not in CI (`melos test` and CI run `test/` only; keep it that way, the Windows desktop app and a display are not available there). Windows by default; `-Device chrome` needs the web bootstrap, which has no offline entry yet.
  - **Keep them current.** After any change to a page, route, widget key, visible label, flow or the demo data, run `scripts/e2e.ps1` and update the affected journeys in the same change; add a journey for a new page or flow. Shared steps live in `integration_test/support/`.
  - One `flutter test` run per file: the Windows app allows a single instance, so a second file cannot launch while the previous app is alive. The scripts handle this; do not run `flutter test integration_test` as a whole.
  - The tests need the demo flags: `--dart-define=SOAR_SCORE_DEMO=true --dart-define=SOAR_SCORE_DEMO_RESET=true`. The scripts pass them. For VS Code, use the `soar_score_contest (E2E, current file)` launch configuration, or for the Testing pane set `dart.flutterTestAdditionalArgs` to those two defines in your own (untracked) `.vscode/settings.json`. Run one file at a time from the pane; running the whole folder fails on the second file for the reason above.
  - Writing journeys: a `ValueKey` on a `Text` or `TextField` is on that widget, so read its `data` or controller instead of `find.descendant(of: key, ...)`. Close any running app instance before a run.
- Platform-specific tests: `flutter test integration_test/platform/`
