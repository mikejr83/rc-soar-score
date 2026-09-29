# Core Package Agent Guide

Domain models, business logic, and scoring engine.

## Structure

- `lib/domain/` — entity classes (Contest, Pilot, Score, Round, etc.)
- `lib/engine/` — scoring engine, discipline-specific calculation
- `lib/services/` — business service classes (scoring, ranking)
- `test/` — unit tests by domain

## Boundaries

- **Pure Dart, no Flutter, no I/O.** Do not import Flutter widgets, platform-specific packages, or network/database code. Must compile and run on any Dart platform.
- Depends on: nothing (or Dart standard library only)
- All scoring rules must trace to `plan/business-requirements/`.

## Testing

- Heavy unit-testing focus. The scoring engine lives here and tests are critical.
- Run: `dart test`
- Coverage goals should be high for the scoring engine.