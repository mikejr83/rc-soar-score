# Ticket 018 — Embed `soar_score_api_handlers` in the Windows Target of `soar_score_contest`

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

015 added the Windows platform to `soar_score_contest`; `plan/architecture-requirements/offline-usage.md` requires that build to run fully disconnected. Per the discussed architecture, the Windows build gets no separate offline-mode UI or client code path — it uses the same `soar_score_api` (008) `ApiClient` the web build uses, just pointed at a local instance of the same API instead of the deployed one. This ticket makes that real: on Windows startup, the app starts an in-process `shelf_io` server on `localhost`, built from `soar_score_api_handlers` (017) wired against `soar_score_data_sqlite` (007) repositories, and constructs `soar_score_api`'s `ApiClient` with that local server's `baseUrl` instead of a remote one.

## Work Items

- [ ] Add a Windows-only startup path in `apps/soar_score_contest` (e.g. `lib/server/embedded_server.dart`, gated by `Platform.isWindows` or an equivalent build-time flag) that: opens/initializes the local SQLite database via `soar_score_data_sqlite`, builds the handler via `soar_score_api_handlers`'s factory, and starts `shelf_io.serve(handler, 'localhost', 0)` (port `0` = OS-assigned free port, avoiding conflicts).
- [ ] Capture the assigned port from the running `HttpServer` and construct `soar_score_api`'s `ApiClient` with `baseUrl: http://localhost:<port>` for the Windows build; the web build continues to construct it with the deployed API's URL — no other client-side code differs between the two.
- [ ] Wire the embedded server's lifecycle to the Flutter app's lifecycle: start it before the first frame that needs API access, and close it (`server.close()`) cleanly on app shutdown.
- [ ] Decide and record where the local SQLite database file lives on disk for the Windows build (e.g. via `path_provider`'s application-support directory).
- [ ] Add a test (or, matching 015's precedent for anything the CLI can't drive headlessly, a documented manual verification) confirming the embedded server starts, `ApiClient.health()` succeeds against it with no network present, and the server stops cleanly on shutdown.
- [ ] Update `README.md`'s execution order to place this ticket after 007, 008, 015, and 017.

## Acceptance Criteria

- [ ] `flutter run -d windows` starts the embedded API server automatically; the app's UI, calling through `soar_score_api`'s `ApiClient`, successfully round-trips a call (e.g. `/health`) against the local instance with no network connectivity present.
- [ ] The web build (`flutter run -d chrome`) is unaffected: it still targets the deployed `soar_score_server` URL, and the embedded-server code path is either not compiled in or a no-op on that platform.
- [ ] The embedded server binds to an OS-assigned free port rather than a fixed one.
- [ ] `flutter test`, `flutter analyze`, and `flutter build windows --release` still pass per ticket 015's baseline.
- [ ] The embedded server shuts down cleanly on app close — no orphaned process or held port after the window closes.

## Dependencies

- [007-scaffold-data-package.md](007-scaffold-data-package.md) — `soar_score_data_sqlite` must exist.
- [008-scaffold-api-package.md](008-scaffold-api-package.md) — `ApiClient`'s `baseUrl` must be required/configurable (amended).
- [015-scaffold-contest-windows-target.md](015-scaffold-contest-windows-target.md) — Windows target must exist.
- [017-extract-api-handlers-package.md](017-extract-api-handlers-package.md) — `soar_score_api_handlers` must exist.

## Sources

- `plan/architecture-requirements/offline-usage.md`
- `plan/implementation-plan.md`