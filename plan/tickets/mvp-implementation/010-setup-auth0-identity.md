# Ticket 010 — Auth0 Identity Setup

- **Category:** Identity
- **Priority:** High
- **Status:** Open

## Context

`plan/implementation-plan.md` mandates Auth0 as the identity provider for the initial release: the API layer decodes JWTs for authn/authz, and client authentication follows OIDC Authorization Code + PKCE using the official Flutter SDK for Auth0. This ticket stands up the Auth0 side (tenant, applications, API entity) and wires the configuration through the codebase and CI.

## Work Items

- [ ] Create/confirm an Auth0 tenant for the project (test tenant for development environment).
- [ ] Create Auth0 application(s):
  - SPA: `soar-score-contest` (web origin, PKCE, allowed callback/logout URLs for dev and any staging origin).
  - SPA: self-scoring + public web origin — decide whether public site needs sign-in at all (read-only results may be anonymous). Record the decision here.
- [ ] Create the Auth0 API entity (audience) named `soar-score-api` in the tenant; the JWT `aud` claim is validated by the API.
- [ ] Configure scopes/roles used later for authz (e.g. `director`, `pilot`, `helper` roles map to scopes or realm roles). Record the role→scope mapping in this ticket so later feature tickets can build on it.
- [ ] Wire configuration into the codebase via environment variables only (never committed):
  - API: `AUTH0_DOMAIN`, `API_AUDIENCE` (and any `AUTH0_JWKS` override for local mock identity during dev).
  - Flutter apps: `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID` (per app), redirect URLs.
  - Provide a root `.env.example` documenting every required variable; add `.env` to `.gitignore`.
- [ ] Integrate Auth0 JWT validation into `soar-score-api` (shelf middleware that verifies signature/JWKS, `aud`, and expiry on `Authorization: Bearer` headers); the public `GET /healthz` stays unauthenticated; all `/api/v1/` routes require a valid token except those explicitly marked public.
- [ ] Integrate the Flutter Auth0 SDK into `soar-score-contest` behind the `TokenProvider` seam established in `soar_score_api` (ticket 008): the app acquires tokens via Authorization Code + PKCE and supplies them to the API client.
- [ ] CI handling: record which secrets CI needs (currently only domain+client IDs for builds; token verification uses public JWKS so no client secret should ever be required — confirm this stays true).

## Acceptance Criteria

- [ ] A valid Auth0 ID/access token is accepted by the API on `/api/v1` routes and rejected with 401 when missing/invalid.
- [ ] Health endpoint works without a token.
- [ ] No `AUTH0_CLIENT_SECRET` or other secret appears in any committed file; `.env.example` documents the variable set.
- [ ] Decision recorded: whether the public site signs users in, and the role→scope mapping for authz.

## Dependencies

- [003-scaffold-dart-api-app.md](003-scaffold-dart-api-app.md)
- [008-scaffold-api-package.md](008-scaffold-api-package.md)
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md)

## Sources

- `plan/implementation-plan.md`
- `plan/business-requirements/accounts.md`
- `plan/architecture-requirements/participant-scoring-access.md`
