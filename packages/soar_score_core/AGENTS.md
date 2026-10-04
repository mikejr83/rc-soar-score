# Core Package Agent Guide

Domain models, business logic, and scoring engine.

## Structure

- `lib/models/` — immutable entity classes for the 48-entity data model, one class per file, grouped by family (contest, participants, matrix, scores, sync, accounts, publication, and so on)
- `lib/enums/` — enumerations that serialize as the exact text values in `plan/data-model/entities/`
- `lib/repositories/` — repository and `SyncStore` contracts only; implementations live in `soar_score_data`
- `lib/disciplines/`, `lib/scoring/` — discipline profiles and the scoring engine
- `lib/services/` — business service classes (scoring, ranking, the server-side sync acceptor)
- `lib/errors/` — typed domain errors and the shared sync reason codes
- `test/` — unit tests by family, mirroring `lib/`

## Boundaries

- **Pure Dart, no Flutter, no I/O.** Do not import Flutter widgets, platform-specific packages, or network/database code. Must compile and run on any Dart platform.
- Depends on: the Dart standard library, `logging`, `equatable` (value equality), and `json_annotation` (annotations only). `json_serializable` and `build_runner` are dev dependencies used to generate the checked-in `.g.dart` serialization code. No other runtime dependencies without updating this file first.
- Must not depend on `soar_score_api`, `soar_score_data`, `soar_score_sync` or any app. Dependencies point inward: those packages depend on core.
- Models are immutable, reference each other by `Id` (never by object graph), and carry no persistence or UI concerns.
- All scoring rules must trace to `plan/business-requirements/`. Field definitions trace to `plan/data-model/entities/`.

## Testing

- Heavy unit-testing focus. The scoring engine lives here and tests are critical.
- Run: `dart test`
- Coverage goals should be high for the scoring engine.
