# Ticket 005 — Scaffold `soar_score_public` (Flutter web)

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

The public web site presents both the project site (landing page, documentation, help) and dense, tabular contest results. Departure from strict Material 3 is allowed where report-like layouts need it (`plan/implementation-plan.md`). This ticket creates the runnable shell: app structure with separate areas for the site pages vs. results pages, and test setup.

## Work Items

- [ ] Create `apps/soar_score_public` via `flutter create` (web platform, project name per `plan/implementation-plan.md`).
- [ ] Add a minimal routing skeleton with distinct route groups: site routes (landing, docs placeholder, help placeholder) and results routes (placeholder results listing), so the later tabular/report UI has a home.
- [ ] Establish the Material 3 `ThemeData` baseline in a dedicated theme file, consistent with the contest app baseline (same seed, independent theme file — the two apps keep separate themes).
- [ ] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- [ ] Add one example widget test (landing route) and one example unit test, both passing.

## Acceptance Criteria

- [ ] `flutter run -d chrome` launches the app; site placeholder routes and results placeholder route render.
- [ ] `flutter test` and `flutter analyze` pass against `soar_score_public`.
- [ ] Route groups make the site-vs-results split visible in the router definitions.

## Dependencies

- [001-setup-toolchain-baseline.md](001-setup-toolchain-baseline.md) — Flutter pin for `flutter create`.
- `plan/implementation-plan.md` — project name and directory convention.

## Sources

- `plan/implementation-plan.md`
- `plan/ui/public-site/README.md`
- `AGENTS.md`
