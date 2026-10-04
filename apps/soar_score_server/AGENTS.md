# Server Agent Guide

Thin executable that wires dependencies, starts the shelf_io server, and exposes the API.

## Structure

- `lib/main.dart` — entry point; parse flags, wire, call `shelf_io.serve`
- `lib/server/server.dart` — startup, dependency injection, port binding
- `lib/middleware/` — auth middleware (JWT validation against JWKS)
- `lib/handlers/` — thin HTTP layer; delegate to `soar_score_api_handlers`

## Boundaries

- **Must NOT contain business logic**. All routing and handler logic lives in `soar_score_api_handlers`; this app only wires and serves.
- Depends on: `soar_score_api`, `soar_score_data` (PostgreSQL executor), `soar_score_api_handlers`
- No Flutter dependencies. Pure Dart CLI executable.

## Authentication and Authorization

Auth0 JWT middleware validates every `/api/v1/*` request (except `/health`). Token verification uses public JWKS. AuthN config: `AUTH0_DOMAIN`, `API_AUDIENCE` env vars.

## Testing

- In-process only. Tests spin up the shelf handler in memory and issue synthetic HTTP requests; no socket/port binding in tests.
- Tests mock repositories from the `soar_score_core` interfaces. No real Postgres needed for handler tests.
- Run: `dart test`

## Auth0 Config

- Server verifies JWKS from `AUTH0_DOMAIN` (public)
- Valid audiences: `soar_score_server`
- Scope/role mapping: `director`, `pilot`, `helper`, `public` (read-only)
