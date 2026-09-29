# soar_score_api_handlers

The shelf routing table for the Soar Score RC sailplane scoring suite, extracted into a shared package that can be hosted by both the deployed server (`soar_score_server`) and the embedded in-process instance in the Windows desktop build (`soar_score_contest`).

This package provides `buildApiHandler`, a factory that constructs the shelf `Handler` for the Soar Score API. Callers supply the server identity (`name`, `displayName`, `version`), the data layer (`ContestRepository`), and an optional auth middleware that applies only to the `/api/v1` subtree (the shared `/health` endpoint always remains public). This single routing table serves both deployed and embedded scenarios: the deployed server wraps it with `shelf_io.serve`.

## Usage

```dart
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

// Build the API handler with your repository and auth middleware
final handler = buildApiHandler(
  name: 'soar_score_server',
  displayName: 'Soar Score API Server',
  version: '0.1.0',
  contests: myRepository,
  authMiddleware: myAuth,  // optional
);

// Serve it (in the deployed server app)
await shelf_io.serve(
  handler,
  InternetAddress.loopbackIPv4,
  8080,
);
```

## Key exports

- `buildApiHandler` — factory that constructs the routing table
- `AuthMiddleware` — typedef for optional auth wrapping (`Handler Function(Handler)`)
- `createHealthHandler(HealthDto identity)` — public `/health` endpoint
- `createStubApiHandler(HealthDto identity)` — `/api/v1/meta` and `/api/v1/ping` endpoints
- `jsonResponse` — helper for building application/json shelf `Response`s

## Auth middleware seam

Pass an `authMiddleware` to wrap the `/api/v1` subtree with token validation. The shared `/health` endpoint stays public (always at `/`). The embedded Windows instance never passes auth middleware, enabling fully offline operation without network-dependent token acquisition. When the middleware returns a 401 response, that response is sent directly, short-circuiting the wrapped handler.

## Tests

```sh
cd packages/soar_score_api_handlers
dart test
```

Tests use an in-memory stub repository (`test/stub_repository.dart`) and no network connections.

## Dependencies

- `soar_score_api` — shared DTOs (`HealthDto`)
- `soar_score_core` — repository interfaces (`ContestRepository`)
- `shelf`, `shelf_router` — HTTP server framework
