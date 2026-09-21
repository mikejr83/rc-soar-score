# Ticket 008 — Scaffold `soar_score_api` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_api` holds the shared API client code used by the Flutter apps (and is referenced by the server app per `AGENTS.md`: "API client/server code"). This ticket establishes the client-side shared package. The actual API routes and DTOs come with feature work; here we define only the client contract types and a transport shim so both Flutter apps have one shared way to talk to the server.

## Work Items

- [ ] Create `packages/soar_score_api` with a `pubspec.yaml` (path dependency on `soar_score_core`; no Flutter dependency).
- [ ] Establish folder structure in `lib/`:
  - `client/` — `ApiClient` class wrapping `package:http`, with a `TokenProvider` callback (no Auth0 yet — that's ticket 010).
  - `dto/` — request/response DTO types, using `json_annotation` per `AGENTS.md`.
  - `errors/` — typed API error types.
- [ ] Add one example DTO (`HealthDto`) and a `ApiClient.health()` method.
- [ ] Add `lib/soar_score_api.dart` exporting the public API.
- [ ] Add unit tests using a mock `http.Client` (no network) for the health call.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.

## Acceptance Criteria

- [ ] `ApiClient` has a single injectable `http.Client` and a single injectable `TokenProvider`; tests inject a mock client.
- [ ] `HealthDto.fromJson`/`.toJson` round-trips in tests.
- [ ] No `package:flutter` in `pubspec.yaml`.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)
- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md) — server health endpoint contract.

## Sources

- `AGENTS.md`
- `plan/implementation-plan.md`
