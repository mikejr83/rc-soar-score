# API Handlers Package Agent Guide

The shelf routing table and handler middleware shared by the deployed server and the embedded Windows instance.

## Structure

- `lib/handlers/` — route handlers by domain (contests, pilots, scores, etc.)
- `lib/middleware/` — shelf middleware (auth, CORS, logging)
- `lib/routing/` — route table construction and router factory `buildApiHandler()`
- `test/` — in-process handler tests (mock repositories, no socket)

## Authorization

Authorization is contest-scoped: every route under `/contests/{id}` checks through `requireContestDirector` (`lib/handlers/contest_authorization.dart`) that the principal is the director of the contest, and answers 404 for an unknown contest and 403 `not_director` for a foreign one — before any body parsing or service call. The `GET /contests` list is scoped to the principal's own contests (plus `Principal.alsoVisibleOwners`); a contest with no stored owner fails closed.

## Boundaries

- **Pure Dart shelf routing only, no transport or database.** Must not import `shelf_io`, `sqlite_*`, `drift`, or any data layer; the caller (`soar_score_server` or the embedded Windows instance) provides repository instances and transport.

## Testing

- In-process only. Spin up the handler stack in memory; issue synthetic HTTP requests. No socket or port binding.

## Testing

- Run: `dart test`
