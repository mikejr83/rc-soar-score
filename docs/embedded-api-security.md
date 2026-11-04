# Embedded API security

The Windows contest app serves the API in process (`apps/soar_score_contest/lib/server/embedded_server.dart`). It has no sign-in: every request acts as the installation's Local account (or the signed-in account once claimed). This page records the threat model and the decision (#425).

## Threat model

- **Other local processes** (same Windows user, or other users on a shared PC) can find the loopback port. Without a check they could read and write all contest data and call `POST /imports/gliderscore`, which reads a file path the caller names.
- **A web page open in the director's browser** can send a cross-site `text/plain` POST to `http://localhost:<port>` without a preflight, so it could write data. With DNS rebinding it could also read responses.

The Auth0 callback listener on port 47821 is separate and out of scope. Malware running as the same user can read the SQLite file directly; this protects against casual and cross-site access, not against that.

## Decision

`embeddedGuard` (`lib/server/embedded_guard.dart`) wraps the embedded handler only; the hosted server keeps `bearerAuth`. In order, a request is refused when:

1. its `Host` is not `localhost:<port>` or `127.0.0.1:<port>` (403, stops DNS rebinding);
2. it carries an `Origin` header (403; the native client never sends one);
3. it has no `Authorization: Bearer <secret>`, or the wrong one (401), compared in constant time. `GET /health` is exempt so connectivity probes need no secret;
4. it writes a body that is not `application/json` (415).

The secret is 32 random bytes generated at each launch, held in memory only and handed to the in-process `ApiClient` through its `tokenProvider` (`EmbeddedServer.secret`). The server binds `InternetAddress.loopbackIPv4` and the base URL is `http://127.0.0.1:<port>`.

## Tests

`apps/soar_score_contest/test/server/embedded_guard_test.dart` covers no token, wrong token, bad `Host`, an `Origin` header, wrong content type and the client round trip. Every other embedded-server test builds its `ApiClient` with the secret.

## Publishing does not run on the embedded server

The embedded server never publishes contests (`publishingEnabled` is off, so its publication routes answer 409 `publishing_not_available`). The Windows app therefore sends publication reads and writes (publish, visibility, delisting, history) to the hosted server through its remote client, with the director's sign-in token (#777). The director must be signed in, and the contest must have synced to the server first; the app says so when either is missing. To try publishing from a debug build, run the API server locally and start the app with `--dart-define=SOAR_SCORE_API_BASE_URL=http://127.0.0.1:8080`.
