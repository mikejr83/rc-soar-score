# soar_score_api

Shared API client for the Soar Score RC sailplane scoring suite. Provides HTTP transport, request/response DTOs, and typed error handling used by both the Flutter web apps and the Windows desktop build.

`ssoar_score_api` wraps `package:http` behind an `ApiClient` that uses injection for transport and token handling. DTOs are serialized with `json_annotation` (codegen via `json_serializable`). Error types (`ApiException`, `ApiHttpError`, `ApiNetworkError`) let callers distinguish transport failures from HTTP status errors. The client makes no assumptions about server location — `baseUrl` is always caller-supplied, enabling the same client code to target the deployed server in web builds or a local embedded instance in the Windows offline build (ticket 017/018).

## Key classes

- `ApiClient` — HTTP client with injectable transport and `TokenProvider`
- `HealthDto` — payload for `GET /health` (server status/health check)
- `ApiException`, `ApiHttpError`, `ApiNetworkError` — typed API error hierarchy

## Token handling

Pass a `TokenProvider` function (`Future<String?> Function()`) to the `ApiClient` constructor. The client calls it per request and sends a `Bearer` auth header when it returns non-null. Returning `null` omits the header (for public endpoints like `/health`). The provider is called lazily, so token refresh can be handled externally.

## Regenerating DTOs

After adding or changing DTO fields, run:

```sh
melos exec --name=soar_score_api -- dart run build_runner build --delete-conflicting-outputs
```

## Tests

```sh
cd packages/soar_score_api
dart test
```

All API client tests use `MockClient` (no network required).
