# Backend plan: call the GliderScore tooling from the Dart application

Backend-side work to make the vendored `gs_importer` tooling callable by the
Flutter app, and to surface what it reads as a new API. A new import wizard
(owned by another agent) will consume this endpoint; the existing New Contest
wizard is **not** touched.

## Grounding

- Tooling: `tools/gs_importer/` (committed `1b0e92c`). Contract in
  `tools/gs_importer/README.md`:
  - `gs_importer/mdb-tables.exe <path.mdb>` → user table names, space
    separated, stdout, exit 0 on success.
  - `gs_importer/mdb-json.exe -T "%Y-%m-%dT%H:%M:%S" <path.mdb> <table>` →
    one strict JSON object per row per line, stdout only.
  - Errors → stderr + non-zero exit. Nulls are **omitted keys**; binary/OLE
    columns are `{"$binary": "<base64>", "$type": "00"}`; dates come back naive
    ISO 8601 thanks to the `-T` flag.
- Availability: the app's `windows/CMakeLists.txt` installs the four files into
  `gs_importer/` next to the exe for **every** config (Debug/Profile/Release)
  because `CMAKE_VS_INCLUDE_INSTALL_TO_DEFAULT_BUILD 1` makes `install` part
  of the default build. Verified: present in
  `build/windows/x64/runner/Release/gs_importer/` **and** `.../Debug/gs_importer/`
  after `flutter build windows --{release,debug}`. So there is no dev vs
  release split; the app finds the helper relative to
  `Platform.resolvedExecutable` (same pattern as
  `lib/auth/auth_session_factory_native.dart:19`).
- Reference DB for manual tests: `S:\Shared\GliderScoreData.mdb` (not in the
  repo). Real table list (from `mdb-tables.exe`): `AudioSettings CompPilots
Comps CompSeries CountryCodes CustomReportsData DBParams Dis Dur
DurTargetTimeByRound F3K F3KTaskByRound F5B LndgNames LndgPoints Pilots
QRCodeSpecs Roles Scores Spd TimerNames TimerSettings ModelNames DeviceNames
F5K F5KBonusNames F5KBonusData F5KTaskandRefHeightByRound`. Note: **no
  `Tasks` table.** `Scores` has 6,522 rows in that DB.
- Constraint: native Windows only. The web build and the hosted
  `soar_score_server` must stay untouched — no new dependency in their compile
  closures. The existing web-closure test
  (`test/platform/web_closure_test.dart`) must keep passing.

## Architecture

Process launching stays out of the pure-Dart layers. The seam, top to bottom:

1. **Port (contract)** — abstract `GliderScoreImportRunner` in
   `soar_score_core`. Pure Dart, no I/O. The handler/service depends only on
   this.
2. **Process implementation** — `GliderScoreImportProcessRunner` in
   `soar_score_data` (the data layer already does native I/O via `dart:io`/
   `sqlite3` FFI). Spawns `Process.run`, locates the binary, maps exit codes
   and stderr to typed errors.
3. **Parsing/orchestration service** — `GliderScoreImportService` in
   `soar_score_core/services` (pure Dart). Validates input, streams each
   table's JSONL, parses, validates, and builds a typed snapshot the
   persistence step will consume.
4. **HTTP** — `POST /api/v1/imports/gliderscore` in
   `soar_score_api_handlers`, wired at the embedded-server call site only.

Why the DB file is not uploaded to the API: the embedded server and the app
share one process; the file is read directly by the helper. A `path` argument
is therefore sufficient, and no upload plumbing or temp-file juggling is
needed. (If a hosted endpoint is ever needed, that is a later decision.)

## File-by-file changes

### `packages/soar_score_core`

- `lib/import/glider_score_import_runner.dart` (new, under a new `import/`
  family, exported from `soar_score_core.dart`):
  - `abstract interface class GliderScoreImportRunner` with
    `Future<ImportAvailability> availability()`,
    `Future<List<String>> listTables(String dbPath)`, and
    `Future<ImportTableStream> exportTable(String dbPath, String table)`
    where `ImportTableStream` exposes `Stream<Map<String, Object?>> rows`
    (already JSON-decoded per line) plus the table name.
  - Result/availability types (`ImportAvailability` with
    `available/executablePath/reason`).
- `lib/errors/glider_score_import_error.dart` (new), one code per failure, all
  extending a `GliderScoreImportError` base:
  - `UnavailableError` — feature absent (non-Windows, helper missing) → maps
    503 `import_unavailable`.
  - `DatabaseNotFoundError` — path missing / not a file → 404
    `import_not_found`.
  - `UnsupportedFileError` — not a `.mdb` → 415 `import_unsupported`.
  - `CorruptDatabaseError` — `mdb-tables`/`mdb-json` exit non-zero with a
    recognizable failure → 422 `import_corrupt`.
  - `MalformedTableError` — a row line is not valid JSON → 422
    `import_malformed`.
  - `TableMissingError` — requested table not in the DB → 404
    `import_table_not_found`.
- `lib/models/imports/glider_score_import_result.dart` (new): typed result of
  one successful read, e.g. `GliderScoreImportResult { id, sourceDbFile,
toolVersion, List<GsTable> tables }`; `GsTable { name, rowCount,
List<Map<String, Object?>> rows }`. Keep rows as maps for now — the later
  wizard does the GliderScore→Soar Score field mapping, not this layer.
- `lib/services/glider_score_import_service.dart` (new):
  - `importFile(GliderScoreImportRunner runner, {required String dbPath,
Set<String>? tables})` → `GliderScoreImportResult`.
  - Validates the path (exists, `.mdb` suffix), calls `listTables`, resolves
    the requested subset (default: every user table), streams each table in
    order, counts rows, and applies a row cap (e.g. 200 000/table, with a
    `rowCapExceeded` flag on the table rather than a hard error — GliderScore
    files are small; the cap is a safety net).
  - Pure: takes the runner, so the whole pipeline is unit-testable with a
    fake runner. No Flutter, no `dart:io`.
- Tests: `test/services/glider_score_import_service_test.dart` (fake runner),
  `test/models/imports/glider_score_import_result_test.dart` if you add
  serialization, plus error-construction tests.

### `packages/soar_score_data`

- `lib/import/glider_score_import_process_runner.dart` (new):
  - `GliderScoreImportProcessRunner implements GliderScoreImportRunner`.
  - `availability()`: check for
    `Platform.resolvedExecutable`'s directory + `gs_importer/mdb-json.exe`;
    allow an override directory (constructor param or env var) so tests and
    future installs can redirect. Returns `ImportAvailability` with the
    resolved path or a reason.
  - `listTables` / `exportTable`: `Process.run` the helper, capture stdout.
    `exportTable` chunks stdout and streams one decoded JSON object per line
    via `const Utf8Decoder()` + line split; decode failures become
    `MalformedTableError`. Exit != 0 → `CorruptDatabaseError` carrying stderr
    (truncated to ~500 chars) in the message. A `ProcessException` from
    spawn → `UnavailableError`.
  - The helper is 32-bit running under WoW64; `Process.run` handles it.
    Set `mode: ProcessStartMode.normal` (default) — no console flicker on
    Windows for GUI child processes.
- Tests: `test/import/glider_score_import_process_runner_test.dart` unit tests
  with a stubbed process executor (the runner should take an injectable
  `Process.run`-shaped function, or be tested against a tiny fixture exe);
  plus an opt-in integration test (skipped when `Platform.environment` lacks a
  `GS_IMPORTER_TEST_DB`) that runs the real vendored binaries against
  `S:\Shared\GliderScoreData.mdb` and asserts the table list and a `Scores`
  row count above a floor. Keep this file in
  `test/import/` but guard it so CI without the DB file still passes.
- Export the runner from `soar_score_data.dart` only if the app needs the
  concrete type (it does, to construct it for the embedded server).

### `packages/soar_score_api_handlers`

- `lib/dto/import_gliderscore_request.dart` (new): `path` (string, required),
  optional `tables` (list of names). `fromJson` throws `ArgumentError` on bad
  shapes (the middleware maps to 400).
- `lib/dto/import_gliderscore_response.dart` (new): mirrors
  `GliderScoreImportResult` as a plain JSON DTO (`schema:
"gs-import/v1"`).
- `lib/handlers/import_handlers.dart` (new):
  `void addImportRoutes(Router router, GliderScoreImportRunner? runner)`.
  - `POST /imports/gliderscore` → when `runner == null`, answer 503
    `import_unavailable` (route present but inert). Otherwise:
    `readJsonBody`, call `GliderScoreImportService`, return
    `jsonResponse(result.toJson(), statusCode: 201)`.
  - The handler must not import `dart:io`, `sqlite3`, or any app package.
    The service comes in as a dependency, the runner likewise — this keeps
    the "pure shelf, no I/O" boundary intact (see the package `AGENTS.md`).
- `lib/handlers/handlers.dart`: add a
  `GliderScoreImportRunner? gliderScoreImport` parameter to
  `createHandlers` and call `addImportRoutes(router, gliderScoreImport)`.
- `lib/handler.dart`: pass a new
  `GliderScoreImportRunner? gliderScoreImport` from `buildApiHandler`.
- `lib/middleware/error_mapping.dart`: add an `on GliderScoreImportError`
  clause before the generic catch, mapping each error to its status/code
  (503/404/415/422 as above).
- Tests: `test/import_handlers_test.dart` — in-process, synthetic requests,
  fake runner; cover 200/201 happy path, each error mapping, and the
  `runner == null` 503. No sockets.

### `apps/soar_score_contest`

- `lib/server/embedded_server.dart`: construct and pass the runner. The
  construction needs `GliderScoreImportProcessRunner` from `soar_score_data`
  (already a dependency of the app for the data layer). Pass
  `gliderScoreImport: GliderScoreImportProcessRunner()` to `buildApiHandler`
  in `initialize()`. No other change needed: the helper is installed next to
  the exe by CMake, and the runner locates it via
  `Platform.resolvedExecutable`.
- **Do not** modify `apps/soar_score_server` — the hosted server stays without
  the runner (`gliderScoreImport` null → 503 there).
- `lib/api_client_provider.dart` or wherever the app's `ApiClient` is
  constructed: no change here, but the **new import wizard** (other agent)
  will call a new client method — so add the client method now:
- `packages/soar_score_api/lib/client/api_client.dart`: add
  `Future<ImportGliderscoreResponse> importGliderScore(String path,
{List<String>? tables})` posting to `/imports/gliderscore`, plus the two
  DTOs imported here (new files in `lib/dto/`). Follow the existing client
  conventions (injected `http.Client`, `TokenProvider`, typed errors).
- `packages/soar_score_api/lib/soar_score_api.dart`: export the new DTOs.
- `test/server/embedded_server_test.dart`: add one test that the embedded
  server exposes `POST /api/v1/imports/gliderscore` and answers 503 on web /
  when the runner is unavailable, and (on Windows with the tooling present)
  201 for a minimal in-test generated `.mdb` if feasible; otherwise assert
  the route exists and the error path. Keep it platform-guarded so it passes
  on CI without the helper.
- `test/app_api_client_test.dart`: unit test the new client method with a
  mock `http.Client`.

### Docs

- `docs/windows-installer-requirements.md`: note the installer now ships
  `gs_importer/` alongside the app (already true as of `1b0e92c`; the note
  here keeps the doc current).
- A short `plan/` note (this file) stays the source of truth for the backend
  contract; a later wizard ticket references it.

## What this does not include

- The import wizard UI, its route, rail entry, and any mapping from
  GliderScore fields to Soar Score entities (contest, pilots, scores).
- Persistence of the imported data into the contest repository (a later
  `POST` with a mapping, or a follow-up step in the same request — decided
  with the wizard owner).
- Support for the hosted server; native Windows only.
- Any changes to `soar_score_sync`.

## Suggested verification

1. `melos analyze` clean.
2. `melos test` green (including the handler in-process tests and the app's
   web-closure test).
3. On Windows: `flutter run --debug` the app, POST
   `localhost:<port>/api/v1/imports/gliderscore` with
   `{"path": "S:\\Shared\\GliderScoreData.mdb"}`, confirm the 201 body has the
   26 table names and `Scores` with 6,522 rows.
4. Negative checks: missing path → 404, `.txt` path → 415, non-.mdb binary
   file → 422.
5. `npx prettier --check "**/*.md"` clean (use
   `& "C:\Program Files\nodejs\npx.cmd"` — `npx.ps1` is blocked by
   ExecutionPolicy in this environment).
