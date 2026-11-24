# Server Agent Guide

Thin executable that wires dependencies, starts the shelf_io server, and exposes the API.

## Structure

- `lib/main.dart` — entry point; parse flags, wire, call `shelf_io.serve`
- `lib/server.dart` — startup, dependency injection, port binding
- `lib/auth/` — Auth0 token verification (JWKS) and the `/userinfo` profile source
- `tool/e2e_server.dart` � test-only server for the web E2E tests: SQLite, demo data, **no token checks**. Never deploy it. With `--profile server` it also has a pilot account (Penny Pilot, verified email): a request with `Authorization: Bearer e2e-pilot` acts as it, any other as the director, and `POST /__e2e/pilot-account-link` (`tool/e2e_pilot_account.dart`) puts it in front of a participation as an "Is this you?" candidate or a confirmed link, for the signed-in self-scoring journeys (#546).
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

## Guest sessions

`/api/v1/self-scoring/*` is mounted before `/api/v1`, so it skips the Auth0 layer and answers to its own guest session (`guestSessionAuth`, a `ParticipantPrincipal`). `INVITATION_SECRET` turns it on; without it the routes answer 409 `invitations_not_available`. The director's side is `GET`/`POST /api/v1/contests/{id}/invitations` (`invitation_handlers.dart`): list the active links, issue for the listed pilots, never email (#790); links are built from `SELF_SCORING_BASE_URL`. Opening a link is throttled per caller address by `InvitationThrottle`, with counters in the `request_throttles` table (shared by every machine); `TRUSTED_PROXY_SECRET` lets the site's `/api` proxy name the visitor (docs/deploy-api-fly.md, "Throttling invitation links"). The slice test `test/api_slice/invitations_slice_test.dart` runs it on SQLite and PostgreSQL.

## Account links

`ParticipantLinkService` (core) links a pilot's account to a director's participant profile: from the directory, from an invitation, or by a confirmed email match. Confirming a link claims the entries of the profile's guest accounts in one transaction; ending one hands the invitations back to their guests. The pilot's account routes (`account_link_handlers.dart`, behind Auth0, 409 `invitations_not_available` without an invitation secret): `GET /account/participations`, `GET /account/link-candidates`, `POST /account/link-candidates/{id}/confirm` and `/decline` (`{id}` is the candidate's own opaque `id`, never the director's profile id), `GET /account/links`, `POST /account/links/{id}/end`. Reads write nothing; `already_linked` is 409 and any id that is not the caller's own is 404 `link_not_found`. `POST /account/invitation-claims` (body `{credential}`, "Continue as ...?" after opening a link while signed in) confirms the link, claims the guests' entries and answers like `/self-scoring/invitations/resolve`, with a session that acts as the account; it shares the anonymous link's `InvitationThrottle` (same 404 `invalid_invitation`, same 429). `POST /account/participations/{id}/session` opens a contest of the list the same way (404 `link_not_found` for any participation not on the caller's list). An account session (its `acct` is not the invitation's own guest) is checked against the Confirmed link on every request, so ending the link ends it at once, and the link then opens anonymously again as the guest. `test/api_slice/participant_links_slice_test.dart` (service) and `account_links_slice_test.dart` (routes) and `account_sessions_slice_test.dart` (claim, open-from-list, session) run on SQLite and PostgreSQL. A column that a guest can write must be listed in `guestAccountReferences` (`soar_score_data`), or a test fails.
