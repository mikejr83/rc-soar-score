# API Handlers Package Agent Guide

The shelf routing table and handler middleware shared by the deployed server and the embedded Windows instance.

## Structure

- `lib/handlers/` — route handlers by domain (contests, pilots, scores, etc.)
- `lib/middleware/` — shelf middleware (auth, CORS, logging)
- `lib/routing/` — route table construction and router factory `buildApiHandler()`
- `test/` — in-process handler tests (mock repositories, no socket)

## Boundaries

- **Pure Dart shelf routing only, no transport or database.** Must not import `shelf_io`, `sqlite_*`, `drift`, or any data layer; the caller (`soar_score_server` or the embedded Windows instance) provides repository instances and transport.

## Testing

- In-process only. Spin up the handler stack in memory; issue synthetic HTTP requests. No socket or port binding.

## Testing

- Run: `dart test`
