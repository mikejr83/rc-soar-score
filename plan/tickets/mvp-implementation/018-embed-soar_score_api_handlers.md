# Ticket 018 — Embed `soar_score_api_handlers` in the Windows Target of `soar_score_contest`

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

015 added the Windows platform to `soar_score_contest`; `plan/architecture-requirements/offline-usage.md` requires that build to run fully disconnected. Per the discussed architecture, the Windows build gets no separate offline-mode UI or client code path — it uses the same `soar_score_api` (008) `ApiClient` the web build uses, just pointed at a local instance of the same API instead of the deployed one. This ticket makes that real: on Windows startup, the app starts an in-process `shelf_io` server on `localhost`, built from `soar_score_api_handlers` (017) wired against `soar_score_data_sqlite` (007) repositories, and constructs `soar_score_api`'s `ApiClient` with that local server's `baseUrl` instead of a remote one.

**Note on ticket 017's file identity:** the "017" this depends on is the `soar_score_api_handlers` extraction ticket, whose file is `017-sqlite-sync-schema.md` (repurposed in commit 2541de5; see that file's Follow-ups). The sync-schema spec that file's original number referred to is a separate, still-orphaned concern.

## Work Items

- [x] Add a Windows-only startup path in `apps/soar_score_contest` (e.g. `lib/server/embedded_server.dart`, gated by `Platform.isWindows` or an equivalent build-time flag) that: opens/initializes the local SQLite database via `soar_score_data_sqlite`, builds the handler via `soar_score_api_handlers`'s factory, and starts `shelf_io.serve(handler, 'localhost', 0)` (port `0` = OS-assigned free port, avoiding conflicts). Gating is the compile-time conditional import in `lib/main.dart` (`bootstrap.dart if (dart.library.js_interop) bootstrap_web.dart`) — the Web build never compiles the native branch at all, which is stronger than a runtime `Platform.isWindows` check.
- [x] Capture the assigned port from the running `HttpServer` and construct `soar_score_api`'s `ApiClient` with `baseUrl: http://localhost:<port>` for the Windows build; the web build continues to construct it with the deployed API's URL — no other client-side code differs between the two. `EmbeddedServer.port` reads `HttpServer.port` and `baseUrl` is derived from it; `NativeBootstrap` constructs `ApiClient(baseUrl: server.baseUrl)`.
- [x] Wire the embedded server's lifecycle to the Flutter app's lifecycle: start it before the first frame that needs API access, and close it (`server.close()`) cleanly on app shutdown. `main()` awaits `bootstrap.start()` before `runApp`; `SoarScoreContestApp.dispose()` calls `bootstrap.close()`, which is idempotent and also closes the SQLite database.
- [x] Decide and record where the local SQLite database file lives on disk for the Windows build (e.g. via `path_provider`'s application-support directory). **Recorded:** `soar_score.db` inside `path_provider`'s application-support directory — `%APPDATA%\<organization>\<app>\soar_score.db` on Windows (the Roaming profile; verified live as `%APPDATA%\com.example\soar_score_contest\soar_score.db`).
- [x] Add a test (or, matching 015's precedent for anything the CLI can't drive headlessly, a documented manual verification) confirming the embedded server starts, `ApiClient.health()` succeeds against it with no network present, and the server stops cleanly on shutdown. `test/server/embedded_server_test.dart` (4 tests) plus a documented live `flutter run -d windows` verification (see Verification).
- [x] Update `README.md`'s execution order to place this ticket after 007, 008, 015, and 017. Done in `plan/tickets/mvp-implementation/README.md`.

## Acceptance Criteria

- [x] `flutter run -d windows` starts the embedded API server automatically; the app's UI, calling through `soar_score_api`'s `ApiClient`, successfully round-trips a call (e.g. `/health`) against the local instance with no network connectivity present. Verified live (server auto-started, logged its URL, and answered `/health`/`/api/v1/meta`/`/api/v1/ping` over loopback) and in-test (`ApiClient.health()` round-trip against the embedded server; the widget tree exposes that client via `test/app_api_client_test.dart`). The UI itself exposes no business routes yet (placeholder routes only), so the round-trip was validated at the client/transport layer, which is the same seam any UI route will use.
- [x] The web build (`flutter run -d chrome`) is unaffected: it still targets the deployed `soar_score_server` URL, and the embedded-server code path is either not compiled in or a no-op on that platform. The web build compiles only `bootstrap_web.dart`; the embedded server, `dart:io`, and the FFI-backed data layer are excluded from the web closure, confirmed by `melos run build` (both web builds) passing.
- [x] The embedded server binds to an OS-assigned free port rather than a fixed one. `shelf_io.serve(handler, 'localhost', 0)`; `test/server/embedded_server_test.dart` asserts the assigned port is in range and is what the client round-trips against.
- [x] `flutter test`, `flutter analyze`, and `flutter build windows --release` still pass per ticket 015's baseline. `flutter build windows --release` built successfully and `scripts/verify.ps1` PASSED (all packages clean; both Flutter app suites pass, including the new embedded-server tests).
- [x] The embedded server shuts down cleanly on app close — no orphaned process or held port after the window closes. Verified live: after closing the window, `soar_score_contest.exe` exited and the bound port was no longer held (`Get-NetTCPConnection` returned nothing).

## Files changed

- `apps/soar_score_contest/lib/platform/app_bootstrap.dart` — new; `AppBootstrap`, the shared view both platform bootstraps expose (`apiClient` + idempotent `close()`).
- `apps/soar_score_contest/lib/platform/bootstrap.dart` — new; `NativeBootstrap` (the native branch of `main.dart`'s conditional import). Resolves the local database path and starts the embedded server, logging the loopback URL.
- `apps/soar_score_contest/lib/platform/bootstrap_web.dart` — new; `WebBootstrap` (the web branch). No embedded server; constructs the `ApiClient` for the deployed URL, overridable at build time via `--dart-define=SOAR_SCORE_API_BASE_URL=...`.
- `apps/soar_score_contest/lib/server/embedded_server.dart` — new; `EmbeddedServer` and `startEmbeddedServer`: opens the SQLite database, forces first-query migration, wires `ContestSqliteRepository` into `buildApiHandler`, `shelf_io.serve`s on `localhost:0`, exposes `port`/`baseUrl`, and `close()`s both the server and the database.
- `apps/soar_score_contest/lib/api_client_provider.dart` — new; `ApiClientInherited` + `apiClientOf(context)`, the seam that exposes the bootstrapped `ApiClient` to the widget tree.
- `apps/soar_score_contest/lib/main.dart` — platform selection moved to a compile-time conditional import (`bootstrap.dart if (dart.library.js_interop) bootstrap_web.dart`); `main()` awaits `bootstrap.start()` before `runApp` and hands the bootstrap to the app.
- `apps/soar_score_contest/lib/app.dart` — now stateful: accepts the optional `bootstrap`, wraps the router in `ApiClientInherited`, and closes it on dispose (the Windows clean-shutdown hook).
- `apps/soar_score_contest/pubspec.yaml` — added `path`, `path_provider`, `shelf`, and path dependencies on `soar_score_api`, `soar_score_api_handlers`, and `soar_score_data_sqlite`.
- `apps/soar_score_contest/windows/flutter/generated_plugins.cmake` — regenerated by `flutter run -d windows`: the Windows FFI plugin list gained `jni` (transitive FFI dependency of `path_provider`).
- `apps/soar_score_contest/test/server/embedded_server_test.dart` — new; 4 tests: health on an OS-assigned free port, loopback health round-trip, clean shutdown + port release, and the SQLite file opening at the requested path.
- `apps/soar_score_contest/test/app_api_client_test.dart` — new; widget tests for the client-provider seam: bootstrapped client exposed to the tree, absent client stays absent, and dispose closes the bootstrap.
- `pubspec.yaml` — workspace globs narrowed from `apps/**`/`packages/**` to `apps/*`/`packages/*` (with a comment): the `**` pattern pulled the Flutter ephemeral plugin symlinks (`apps/<app>/windows/flutter/ephemeral/.plugin_symlinks`) into the workspace, where they fail resolution because they lack `resolution: workspace`.
- `pubspec.lock` — workspace lockfile updated by `melos bootstrap` for the new dependencies (`path_provider` + platform packages, `jni`/`jni_flutter`/`jni_util`/`objective_c` transitive FFI runtime).

## Verification

- `scripts/verify.ps1`: **PASSED** (bootstrap; format check clean across all 9 packages; `melos analyze --fatal-infos` clean in all 9; `melos test` — `soar_score_contest` 10/10 including the 4 new embedded-server tests and the 3 new client-provider widget tests, all other suites pass; `melos run build` builds both web apps and the server executable).
- `flutter build windows --release` in `apps/soar_score_contest`: built `build\windows\x64\runner\Release\soar_score_contest.exe`.
- Live `flutter run -d windows`: the embedded server auto-started and logged `http://localhost:60050`. From the shell: `GET /health` and `GET /api/v1/meta` → `{"name":"soar_score_contest","displayName":"Soar Score Contest (Offline)","version":"0.1.0"}`, `GET /api/v1/ping` → `{"status":"ok"}`, unknown route (`/api/v1/nope`) → 404. The SQLite file was created at `%APPDATA%\com.example\soar_score_contest\soar_score.db` (the Roaming application-support directory).
- Clean shutdown: after closing the window, `soar_score_contest.exe` exited on its own and `Get-NetTCPConnection -LocalPort 60050` returned nothing — no orphaned process, no held port.

## Follow-ups

- Business routes: the embedded server currently serves only the identity/placeholder routes (`/health`, `/api/v1/meta`, `/api/v1/ping`) that 017 extracted; real `/api/v1` endpoints (feature tickets) will exercise the wired `ContestSqliteRepository`.
- The orphaned SQLite sync-schema spec (mutation log, sync cursors, tombstones, revision/bookkeeping columns per `plan/architecture-requirements/offline-synchronization.md`) lost its home when ticket 017's file was repurposed; it needs its own ticket number (see `017-sqlite-sync-schema.md`'s Follow-ups). Tickets 007 and 016 still point at that file for it.
- The app's `pubspec` org identifier is `com.example` (the Flutter template default); a real organization name should be set before distribution.

## Dependencies

- [007-scaffold-data-package.md](007-scaffold-data-package.md) — `soar_score_data_sqlite` must exist.
- [008-scaffold-api-package.md](008-scaffold-api-package.md) — `ApiClient`'s `baseUrl` must be required/configurable (amended).
- [015-scaffold-contest-windows-target.md](015-scaffold-contest-windows-target.md) — Windows target must exist.
- [017-sqlite-sync-schema.md](017-sqlite-sync-schema.md) — `soar_score_api_handlers` must exist (that file was repurposed to the extraction ticket in commit 2541de5).

## Sources

- `plan/architecture-requirements/offline-usage.md`
- `plan/implementation-plan.md`