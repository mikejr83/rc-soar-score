# Ticket 006 — Scaffold `soar_score_core` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_core` holds domain models, business logic, and the scoring engine per `AGENTS.md`. It is a pure Dart package — it must not depend on `package:flutter` so it stays testable and reusable from both the API and Flutter apps. This ticket creates the package skeleton with the folder structure the domain will grow into; domain entities and the scoring engine themselves are later workstreams.

## Work Items

- [ ] Create `packages/soar_score_core` with a `pubspec.yaml` (name `soar_score_core`, Dart SDK per ticket 001).
- [ ] Establish folder structure in `lib/`:
  - `models/` — domain model types will live here.
  - `scoring/` — discipline profiles and scoring engine will live here.
  - `disciplines/` — per-discipline rule logic (ALES, F3J, F5J, Thermal) will live here.
  - `errors/` — domain error types.
- [ ] Add a small example domain type (e.g. an `Id` value object or a minimal `ContestState` enum) in `models/` to prove the structure compiles.
- [ ] Add `lib/soar_score_core.dart` exporting the public API.
- [ ] Add one passing unit test that exercises the example type.
- [ ] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.
- [ ] No `package:flutter` dependency — verify in `pubspec.yaml`.

## Acceptance Criteria

- [ ] `dart test` and `dart analyze` pass from the package directory.
- [ ] `pubspec.yaml` has no flutter/sqflite/ui dependencies.
- [ ] The exported public API file is the only required import for consumers.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md)
- `plan/implementation-plan.md` — package name and directory convention.

## Sources

- `AGENTS.md`
- `plan/architecture-requirements/data.md`
- `plan/architecture-requirements/discipline-scoring.md`
