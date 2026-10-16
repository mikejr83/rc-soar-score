# Server Agent Guide

Thin executable that wires dependencies, starts the shelf_io server, and exposes the API.

## Structure

- `lib/main.dart` — entry point; parse flags, wire, call `shelf_io.serve`
- `lib/server.dart` — startup, dependency injection, port binding
- `lib/auth/` — Auth0 token verification (JWKS) and the `/userinfo` profile source
- `tool/e2e_server.dart` � test-only server for the web E2E tests: SQLite, demo data, **no token checks**. Never deploy it.
- `lib/handler.dart` — wires `soar_score_api_handlers` to the repositories

## Boundaries

- **Must NOT contain business logic**. All routing and handler logic lives in `soar_score_api_handlers`; this app only wires and serves.
- Depends on: `soar_score_api`, `soar_score_data` (PostgreSQL executor), `soar_score_api_handlers`
- No Flutter dependencies. Pure Dart CLI executable.

## Authentication and Authorization

`bearerAuth` (from `soar_score_api_handlers`) guards every `/api/v1/*` request; `/health` and `/public/*` stay open. `Auth0TokenVerifier` checks the RS256 signature against the tenant's public JWKS, `exp`, `iss` (`https://<AUTH0_DOMAIN>/`) and `aud`. `AccountPrincipalResolver` maps the issuer and subject to a registered account, creating it on first sign-in from `/userinfo`, and sets the request's `Principal`. Both `AUTH0_DOMAIN` and `API_AUDIENCE` are required; the server does not start without them.

## Testing

- In-process only. Tests spin up the shelf handler in memory and issue synthetic HTTP requests; no socket/port binding in tests.
- Tests mock repositories from the `soar_score_core` interfaces. No real Postgres needed for handler tests.
- Run: `dart test`

## Auth0 Config

- Server verifies JWKS from `AUTH0_DOMAIN` (public)
- Valid audience: `https://soar-score.com/server` (the API identifier in Auth0; set as `API_AUDIENCE`)
- No Auth0 roles or scopes: authorization comes from backend relationships (ownership, invitations), see `plan/architecture-requirements/data/accounts.md`
