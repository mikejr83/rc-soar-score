# Ticket 006 — Scaffold `soar_score_core` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** In-Review

## Context

`packages/soar_score_core` holds domain models, business logic, and the scoring engine per `AGENTS.md`. It is a pure Dart package — it must not depend on `package:flutter` so it stays testable and reusable from both the API and Flutter apps. This ticket creates the package skeleton with the folder structure the domain will grow into; domain entities and the scoring engine themselves are later workstreams.

## Work Items

- [x] Create `packages/soar_score_core` with a `pubspec.yaml` (name `soar_score_core`, Dart SDK per ticket 001).
- [x] Establish folder structure in `lib/`:
  - `models/` — domain model types will live here.
  - `scoring/` — discipline profiles and scoring engine will live here.
  - `disciplines/` — per-discipline rule logic (ALES, F3J, F5J, Thermal) will live here.
  - `errors/` — domain error types.
- [x] Add a small example domain type in `models/` to prove the structure compiles: an `Id` value object plus a minimal `Contest` domain object carrying it (per maintainer guidance during implementation).
- [x] Add `lib/soar_score_core.dart` exporting the public API.
- [x] Add one passing unit test that exercises the example type (two test files: `Id`, `Contest`).
- [x] Add `analysis_options.yaml` including `package:lints/recommended.yaml`.
- [x] No `package:flutter` dependency — verified in `pubspec.yaml`.

## Acceptance Criteria

- [x] `dart test` and `dart analyze` pass from the package directory. Verified: `dart analyze` → "No issues found!"; `dart test` → 12/12 passing (Dart 3.13.3).
- [x] `pubspec.yaml` has no flutter/sqflite/ui dependencies. Only dev deps `lints` and `test`; no runtime dependencies at all.
- [x] The exported public API file is the only required import for consumers. Both tests import only `package:soar_score_core/soar_score_core.dart`.

## Files changed

- `packages/soar_score_core/pubspec.yaml` — new; name `soar_score_core`, version 0.1.0, `publish_to: none`, SDK `>=3.13.0 <4.0.0` (Dart 3.13.x bundled with Flutter 3.47.x per ticket 001); dev deps `lints ^6.1.0`, `test ^1.32.0`; no runtime dependencies (no flutter/sqflite/ui).
- `packages/soar_score_core/pubspec.lock` — new; committed for reproducible CI builds as in ticket 003.
- `packages/soar_score_core/.gitignore` — new; ignores `.dart_tool/`, `.packages`, `build/` (matches the other projects).
- `packages/soar_score_core/analysis_options.yaml` — new; includes `package:lints/recommended.yaml`.
- `packages/soar_score_core/lib/models/id.dart` — new; `Id` value object: immutable opaque UUIDv7 identifier with `Id.parse` (validates + normalizes to lower-case canonical form), `Id.create()` (offline-safe generation per the data model's identifier requirements), equality/hashCode/`compareTo`/`toString`.
- `packages/soar_score_core/lib/models/contest.dart` — new; minimal `Contest` example domain object carrying an `Id` plus a few example fields (`name`, UTC `startedAt`); explicitly a scaffold placeholder — the full contest model (revisions, matrix, participation, the independent control states from `plan/architecture-requirements/data/contest.md`) is later work.
- `packages/soar_score_core/lib/scoring/README.md` — new; placeholder marking where discipline profiles and the scoring engine will live.
- `packages/soar_score_core/lib/disciplines/README.md` — new; placeholder marking where per-discipline rule logic (ALES, F3J, F5J, Thermal) will live.
- `packages/soar_score_core/lib/errors/README.md` — new; placeholder marking where domain error types will live.
- `packages/soar_score_core/lib/soar_score_core.dart` — new; public API barrel exporting `models/id.dart` and `models/contest.dart`; the only import required by consumers.
- `packages/soar_score_core/test/models/id_test.dart` — new; 7 tests covering `Id.parse` (valid, normalization, malformed/wrong-version rejection), `Id.create()` (parseable UUIDv7, distinctness), equality/hashCode, and `compareTo` ordering. All import only the barrel.
- `packages/soar_score_core/test/models/contest_test.dart` — new; 5 tests covering the example fields, UTC storage of `startedAt`, blank-name rejection, value equality, and `toString`. All import only the barrel.
- `plan/tickets/mvp-implementation/006-scaffold-core-package.md` — this ticket: status In-Review, work items and acceptance criteria checked, decision note, files changed, follow-ups.

## Follow-ups

- Model the full `Contest` domain object (configuration revisions, matrix, participation, scoring access, publication, and the other independent control states per `plan/architecture-requirements/data/contest.md`), replacing the placeholder — domain-entity workstream.
- Populate `scoring/`, `disciplines/`, and `errors/` with their domain content — later workstreams.
- Add a package README if ticket 013's per-project AGENTS.md covers this package (currently only covered at the repo level).

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md)
- `plan/implementation-plan.md` — package name and directory convention.

## Sources

- `AGENTS.md`
- `plan/architecture-requirements/data.md`
- `plan/architecture-requirements/discipline-scoring.md`
