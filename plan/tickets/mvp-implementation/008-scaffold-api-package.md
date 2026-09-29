# Ticket 008 — Scaffold `soar_score_api` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

> **Amendment (architecture):** `soar_score_contest`'s Windows build (015) is intended to run fully offline by hosting the API in-process rather than reaching a deployed server (see 017/018). For that to work, this package's `ApiClient` must never assume a fixed server location — `baseUrl` has to be a required, caller-supplied value, so the *same* client code serves the web build (pointed at the deployed `soar_score_server`) and the Windows build (pointed at a local embedded instance) without any client-side branching. Work items and acceptance criteria below reflect this.

## Context

`packages/soar_score_api` holds the shared API client code used by the Flutter apps (and is referenced by the server app per `AGENTS.md`: "API client/server code"). This ticket establishes the client-side shared package. The actual API routes and DTOs come with feature work; here we define only the client contract types and a transport shim so both Flutter apps have one shared way to talk to the server.

## Decisions

- **`TokenProvider` seam:** `Future<String?> Function()` — asynchronous so ticket 010's Auth0 PKCE flow (token acquire/refresh) can supply a token on demand per request; returning `null` omits the `Authorization` header, so public routes such as `GET /health` work without a token. A synchronous provider can simply `Future.value(token)`.
- **Error taxonomy:** `ApiException` base (a concrete class, so the client's catch-all decode path can throw it directly) with two subtypes, one file each in `errors/`: `ApiHttpError` (non-2xx responses; carries `statusCode` + decoded `body`) and `ApiNetworkError` (transport failure; carries the underlying `ClientException` as `cause`). Every error carries the failed request's `requestUri`.
- **Mock client in tests:** `MockClient` from `package:http/testing.dart` — no extra dependency, no sockets opened.
- **Generated serialization committed:** `health_dto.g.dart` is committed, matching the `soar_score_data_sqlite` convention for codegen output.

## Work Items

- [x] Create `packages/soar_score_api` with a `pubspec.yaml` (path dependency on `soar_score_core`; no Flutter dependency).
- [x] Give `ApiClient` a required `baseUrl` (`Uri`) constructor parameter with no default — every call site must be explicit about which server it targets. This is what lets the same client serve both the web build (deployed `soar_score_server` URL) and the Windows build (a local `http://localhost:<port>` once 017/018 land) with zero client-side platform branching.
- [x] Establish folder structure in `lib/`:
  - `client/` — `ApiClient` class wrapping `package:http`, with a `TokenProvider` callback (no Auth0 yet — that's ticket 010).
  - `dto/` — request/response DTO types, using `json_annotation` per `AGENTS.md`.
  - `errors/` — typed API error types.
- [x] Add one example DTO (`HealthDto`) and a `ApiClient.health()` method.
- [x] Add `lib/soar_score_api.dart` exporting the public API.
- [x] Add unit tests using a mock `http.Client` (no network) for the health call.
- [x] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.

## Acceptance Criteria

- [x] `ApiClient` has a single injectable `http.Client`, a single injectable `TokenProvider`, and a required `baseUrl`; tests inject a mock client and an arbitrary `baseUrl` to confirm no host/port is ever hard-coded. Verified: tests construct clients against two arbitrary base URLs (`http://contest-site.example:8085/api` and `http://localhost:1234`) and assert the outgoing request URL is exactly `baseUrl.resolveUri('/health')`; no host or port literal exists anywhere in `lib/`.
- [x] `HealthDto.fromJson`/`.toJson` round-trips in tests. Verified: `health_dto_test.dart` covers decoding the exact server payload shape (ticket 003's `{name, displayName, version}`), encoding to the same shape, an arbitrary payload round-trip, and value equality.
- [x] No `package:flutter` in `pubspec.yaml`. Verified: runtime deps are `http`, `json_annotation`, and the path dep on `soar_score_core`; dev deps are `build_runner`, `json_serializable`, `lints`, `test`.

## Files changed

### `packages/soar_score_api` (new package)

- `packages/soar_score_api/pubspec.yaml` — new; name `soar_score_api`, version 0.1.0, `publish_to: none`, SDK `>=3.13.0 <4.0.0`; deps `http ^1.6.0`, `json_annotation ^4.12.0`, path dep `soar_score_core`; dev deps `build_runner ^2.16.1`, `json_serializable ^6.14.1`, `lints ^6.1.0`, `test ^1.32.0`. No Flutter dependencies.
- `packages/soar_score_api/pubspec.lock` — new; committed for reproducible CI builds (consumed by ticket 011).
- `packages/soar_score_api/.gitignore` — new; ignores `.dart_tool/`, `.packages`, `build/` (matches the other packages).
- `packages/soar_score_api/analysis_options.yaml` — new; includes `package:lints/recommended.yaml`.
- `packages/soar_score_api/build.yaml` — new; documents the DTO codegen regeneration command (`dart run build_runner build --delete-conflicting-outputs`); json_serializable needs no custom builder config.
- `packages/soar_score_api/lib/client/api_client.dart` — new; `ApiClient`: required `baseUrl` (no default), single injectable `http.Client` (default when omitted), optional `TokenProvider` (`Future<String?> Function()`); `health()` resolves `GET /health` against `baseUrl`, sends `Authorization: Bearer <token>` only when the provider returns a non-null token, throws `ApiHttpError` (status + body) on non-2xx, `ApiNetworkError` on `ClientException`, `ApiException` on an undecodable body; `close()` releases the client.
- `packages/soar_score_api/lib/dto/health_dto.dart` — new; `@JsonSerializable` `HealthDto` (`name`, `displayName`, `version`) matching `soar_score_server`'s live `GET /health` payload (ticket 003); `fromJson`/`toJson`, value equality, `toString`.
- `packages/soar_score_api/lib/dto/health_dto.g.dart` — generated by `json_serializable` (committed; regenerate after field changes).
- `packages/soar_score_api/lib/errors/api_exception.dart` — new; concrete `ApiException` base: `message` + `requestUri`.
- `packages/soar_score_api/lib/errors/api_http_error.dart` — new; `ApiHttpError extends ApiException` with `statusCode` + `body`.
- `packages/soar_score_api/lib/errors/api_network_error.dart` — new; `ApiNetworkError extends ApiException` with optional `cause`.
- `packages/soar_score_api/lib/soar_score_api.dart` — new; public API barrel exporting `client/`, `dto/`, `errors/` (the only import required by consumers).
- `packages/soar_score_api/test/client/api_client_test.dart` — new; 7 tests using `MockClient` (no network): health call resolves `/health` against the given `baseUrl` and decodes the payload, works against a different arbitrary `baseUrl`, sends the Bearer token from the provider, omits the `Authorization` header when the provider returns `null`, throws `ApiHttpError` (status + body) on 403, throws `ApiNetworkError` (carrying the `ClientException`) on transport failure, throws base `ApiException` when the body is not a JSON object.
- `packages/soar_score_api/test/dto/health_dto_test.dart` — new; 4 tests: decodes the server payload shape, encodes to the same shape, round-trips an arbitrary payload, value equality.

### Tickets

- `plan/tickets/mvp-implementation/008-scaffold-api-package.md` — this ticket: status In-Review, decisions recorded, work items and acceptance criteria checked, files changed.
- `plan/tickets/mvp-implementation/README.md` — index: 008 → In-Review.
- `plan/tickets/mvp-implementation/003-scaffold-dart-api-app.md` — follow-up "Wire `soar_score_api`'s `HealthDto` to the actual payload shape" marked done (2026-09-23).

## Verification

- `dart analyze` (`soar_score_api`): "No issues found!" (Dart 3.13.3).
- `dart test` (`soar_score_api`): 11/11 passing.
- `dart analyze`/`dart test` (`soar_score_core`, path-dependency source): unchanged, still passing.

## Follow-ups

- Ticket 017 extracts the shelf handler logic out of `soar_score_server` into a shared package, so it can be hosted both by the real server and embedded elsewhere.
- Ticket 018 embeds that handler (with `soar_score_data_sqlite`, 007) inside the Windows build of `soar_score_contest`, and constructs this package's `ApiClient` with a local `baseUrl` there instead of the deployed one.
- Wire this package into the Melos workspace and its bulk commands (ticket 014).
- Done (2026-09-23, during this ticket's review window): `soar_score_server`'s `/health` and `/api/v1/meta` handlers now serialize through the shared `HealthDto`, so the server and client cannot drift apart (per ticket 013's planned "DTO placement in `soar_score_api`" rule). The server app gained a path dependency on `soar_score_api`; its in-process handler tests still pass unchanged because `HealthDto.toJson()` produces the same payload shape.
- Ticket 010 will supply real tokens through this `TokenProvider` seam (Flutter Auth0 PKCE); no client-side changes are anticipated — the header is already sent whenever a non-null token is provided.
- Add a per-package AGENTS.md with ticket 013's per-project rules (DTOs use `json_annotation`, no Flutter, token handling injected, errors typed in `errors/`).

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)
- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) — server health endpoint contract.

## Sources

- `plan/implementation-plan.md`
