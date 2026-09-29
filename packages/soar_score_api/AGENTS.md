# API Package Agent Guide

Shared API client used by Flutter apps to communicate with `soar_score_server`.

## Structure

- `lib/dto/` — JSON data transfer objects
- `lib/client/` — HTTP client wrapper for all API endpoints
- `lib/errors/` — typed API error classes
- `lib/serialization/` — JSON serialization utilities

## Boundaries

- **Pure Dart, no Flutter.** Must work on web, desktop, and server. Do not import Flutter widgets or platform-specific code.
- JSON serialization via `json_annotation` + `json_serializable` (build_runner generates code).
- Authentication tokens are injected via constructor — package does not manage tokens itself. Token provider interface is defined here; implementations live in the apps.

## Testing

- Unit tests with mock HTTP client (package:test).
- Run: `dart test`