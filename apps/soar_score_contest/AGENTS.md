# Contest App Agent Guide

Contest management application for directors, pilots, and helpers. Runs on web and Windows (embedded offline).

## Structure

- `lib/main.dart` — entry point
- `lib/features/` — page widgets by domain: contests, pilots, score-entry, results
- `lib/server/` — Windows-only embedded offline server logic
- `lib/widgets/` — local reusable widgets (not shared with public app)

## Boundaries

- **Must not do direct database access**. All data access goes through `soar_score_api` client (which talks to `soar_score_api_handlers`, which uses `soar_score_data` backed by SQLite in the native app or by PostgreSQL on the server; the web build has no local database and calls the remote API).
- Depends on: `soar_score_core`, `soar_score_data`, `soar_score_api`, `soar_score_sync`, `soar_score_ui`, `soar_score_ui_storage`
- UI-only state (theme, hidden panels, drafts) goes through `LocalUiStore` from `soar_score_ui_storage`, reached with `localUiStoreOf(context)` (`lib/local_ui_store_provider.dart`; `null` in bare-page tests). Key every call by account id. Contest data never goes through it.
- The New Contest draft is kept per account through `ContestDraftStore.persistence` (`LocalUiDraftPersistence`, key `new_contest_draft`). `ContestDraftCodec.version` is the stored shape: raise it when a draft field changes incompatibly, and older drafts are then offered for discard. Add any new `ContestDraft` field to the codec and its round-trip test.
- Page states: a page that loads, is empty, cannot be reached, is not allowed or has a conflict shows `PageStateView` (`lib/widgets/page_states/page_states.dart`); a problem above still-usable content is a `PageBanner`; a status value gets a `StatusLabel` so it is spoken as "Field: value". Sort an API error with `ApiFailure.of(error)` (`lib/services/api_failure.dart`) instead of matching status codes in the page; it reads the server's `code` first. A load that fails goes through `loadFailedView(error, title:, onRetry:)`, which offers Retry only when `ApiFailure.retryable`. A save that fails shows `SaveFailedBanner` (the form keeps every value; Retry only for retryable failures; Dismiss only closes it) and creates with one id per editor so a Retry cannot duplicate. Use `confirmDiscard(context, ...)` for the discard question and pass your own copy when the page has something specific to say (configuration and the wizard do). `MessageView` is being replaced and should not gain new users.
- Visible text goes through `AppLocalizations` (`lib/l10n/`, ARB files, ADR 0004): add each new string to `lib/l10n/app_en.arb` with a `description`, run `flutter gen-l10n` and commit the generated files, and read it with `AppLocalizations.of(context)`. The Settings page is migrated; other pages still hold their text inline and move over feature by feature (a screen's text stays inline until its widgets are migrated, so do not mix). In tests read expected text from `AppLocalizationsEn()`. Translators work from `docs/translating.md` and `tool/l10n.dart`.
- `soar_score_sync` is imported only by `lib/platform/native_sync.dart` and `native_bootstrap.dart`, so the web build contains no sync engine (`test/platform/web_closure_test.dart` checks it). Screens reach sync state through `AppBootstrap`, never the package.
- The Material themes and shared color tokens live in `soar_score_ui` (`theme/app_theme.dart`): `ContestAppTheme`, `PublicAppTheme`, `SelfScoreAppTheme`, `AppColors`, `AppStatusColors`.

## Design Notes

- Offline-aware: UI must not assume connectivity (see `plan/architecture-requirements/offline-usage.md`). Show pending-changes state, provide manual sync trigger.
- The web build stores no contest data in the browser (IndexedDB is limited to preferences and front-end functionality). The native build syncs on connect, then writes locally first and immediately through the remote API.
- Routing constructs are shared with `soar_score_public` via `soar_score_ui`.
- Mobile-first responsive layouts (see `plan/architecture-requirements/responsive-design.md`).

## Testing

- Widget tests: `flutter test`
- Integration (E2E) tests: `scripts/e2e.ps1` (or `scripts/e2e.sh`) runs `integration_test/` against the real app on the demo database, recreated per run. Local only, not in CI (`melos test` and CI run `test/` only; keep it that way, the Windows desktop app and a display are not available there). Windows by default; `-d web` (`-Device web` in `e2e.ps1`) runs the same journeys in headless Chrome, which is what cloud agents use (see Web mode below).
  - **Keep them current.** After any change to a page, route, widget key, visible label, flow or the demo data, run `scripts/e2e.ps1` and update the affected journeys in the same change; add a journey for a new page or flow. Shared steps live in `integration_test/support/`.
  - One `flutter test` run per file: the Windows app allows a single instance, so a second file cannot launch while the previous app is alive. The scripts handle this; do not run `flutter test integration_test` as a whole.
  - The tests need the demo flags: `--dart-define=SOAR_SCORE_DEMO=true --dart-define=SOAR_SCORE_DEMO_RESET=true`. The scripts pass them. For VS Code, use the `soar_score_contest (E2E, current file)` launch configuration, or for the Testing pane set `dart.flutterTestAdditionalArgs` to those two defines in your own (untracked) `.vscode/settings.json`. Run one file at a time from the pane; running the whole folder fails on the second file for the reason above.
  - Writing journeys: a `ValueKey` on a `Text` or `TextField` is on that widget, so read its `data` or controller instead of `find.descendant(of: key, ...)`. Close any running app instance before a run.
- Web mode: the browser build has no local database and no offline mode, so `-d web` builds the app with `--dart-define=SOAR_SCORE_E2E=true` (`lib/auth/e2e_signed_in_session.dart`, an always-signed-in session that sends no token; ignored in release builds) and points it at `apps/soar_score_server/tool/e2e_server.dart`. That server has no token checks, serves a fresh SQLite database with the system and demo data (every request acts as the Local account, like the Windows embedded server), and allows cross-origin calls. It must never be deployed. `POST /__e2e/fail-next-write` makes its next write answer 503 once (used by `save_failure_retry_test.dart`, which is web-only because the Windows build's embedded server gets no such hook). The scripts start it per test file and run `flutter drive` (`test_driver/integration_test.dart`) with `-d web-server`. Needs Chrome and a matching `chromedriver`: run `scripts/e2e-setup.sh` (or `.ps1`) once to install both into `.e2e-tools/` (git-ignored), where the scripts find them; `CHROMEDRIVER` / `CHROME_EXECUTABLE` override that, and `chromedriver` on PATH is the last resort. **Agents: run the setup script before the first web E2E run.** The scripts fail at once when chromedriver is missing or does not answer, and stop a test file that runs longer than `E2E_TEST_TIMEOUT` seconds (default 300) as failed; a healthy file takes about a minute, so a run that is quiet for longer than that is hung, not slow. Journeys must run on both targets; avoid `dart:io` and native-only screens (Sync) in them, and when a journey is native-only, say so in its file.
- Platform-specific tests: `flutter test integration_test/platform/`
