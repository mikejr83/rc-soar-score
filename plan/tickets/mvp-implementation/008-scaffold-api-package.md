# Ticket 008 — Scaffold `soar_score_api` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

> **Amendment (architecture):** `soar_score_contest`'s Windows build (015) is intended to run fully offline by hosting the API in-process rather than reaching a deployed server (see 017/018). For that to work, this package's `ApiClient` must never assume a fixed server location — `baseUrl` has to be a required, caller-supplied value, so the *same* client code serves the web build (pointed at the deployed `soar_score_server`) and the Windows build (pointed at a local embedded instance) without any client-side branching. Work items and acceptance criteria below reflect this.

## Context

`packages/soar_score_api` holds the shared API client code used by the Flutter apps (and is referenced by the server app per `AGENTS.md`: "API client/server code"). This ticket establishes the client-side shared package. The actual API routes and DTOs come with feature work; here we define only the client contract types and a transport shim so both Flutter apps have one shared way to talk to the server.

## Work Items

- [ ] Create `packages/soar_score_api` with a `pubspec.yaml` (path dependency on `soar_score_core`; no Flutter dependency).
- [ ] Give `ApiClient` a required `baseUrl` (`Uri`) constructor parameter with no default — every call site must be explicit about which server it targets. This is what lets the same client serve both the web build (deployed `soar_score_server` URL) and the Windows build (a local `http://localhost:<port>` once 017/018 land) with zero client-side platform branching.
- [ ] Establish folder structure in `lib/`:
  - `client/` — `ApiClient` class wrapping `package:http`, with a `TokenProvider` callback (no Auth0 yet — that's ticket 010).
  - `dto/` — request/response DTO types, using `json_annotation` per `AGENTS.md`.
  - `errors/` — typed API error types.
- [ ] Add one example DTO (`HealthDto`) and a `ApiClient.health()` method.
- [ ] Add `lib/soar_score_api.dart` exporting the public API.
- [ ] Add unit tests using a mock `http.Client` (no network) for the health call.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.

## Acceptance Criteria

- [ ] `ApiClient` has a single injectable `http.Client`, a single injectable `TokenProvider`, and a required `baseUrl`; tests inject a mock client and an arbitrary `baseUrl` to confirm no host/port is ever hard-coded.
- [ ] `HealthDto.fromJson`/`.toJson` round-trips in tests.
- [ ] No `package:flutter` in `pubspec.yaml`.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)
- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) — server health endpoint contract.

## Follow-ups

- Ticket 017 extracts the shelf handler logic out of `soar_score_server` into a shared package, so it can be hosted both by the real server and embedded elsewhere.
- Ticket 018 embeds that handler (with `soar_score_data_sqlite`, 007) inside the Windows build of `soar_score_contest`, and constructs this package's `ApiClient` with a local `baseUrl` there instead of the deployed one.

## Sources

- `plan/implementation-plan.md`
