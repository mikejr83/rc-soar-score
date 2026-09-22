# Ticket 009 — Scaffold `soar_score_ui` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** Open

## Context

`packages/soar_score_ui` holds the shared Flutter UI components used by `soar_score_contest` and `soar_score_public`. Per `plan/implementation-plan.md`, both apps can share navigation constructs. This ticket sets up the package with a single example reusable widget (a card or app-bar component) so the dependency path into the two Flutter apps is proven.

## Work Items

- [ ] Create `packages/soar_score_ui` with a `pubspec.yaml` (Flutter SDK per ticket 001; path dependency on `soar_score_core`; `flutter` as a direct dependency).
- [ ] Establish folder structure in `lib/`:
  - `widgets/` — reusable leaf widgets.
  - `components/` — larger composite components (cards, tables, forms).
  - `theme/` — shared theme extensions or tokens.
- [ ] Add one reusable widget (e.g. `ScoreCard` or `SectionHeader`) in `widgets/`.
- [ ] Add `lib/soar_score_ui.dart` exporting the public API.
- [ ] Add one `flutter_test` widget test for the example widget, using `flutter_test` bindings.
- [ ] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.
- [ ] Ensure the Melos commands in `014-setup-melos-workspace.md` cover this project: `bootstrap` (flutter pub get), `test` (`flutter test --no-pub`), `analyze` (`flutter analyze --no-pub`). No build step (library).

## Acceptance Criteria

- [ ] `flutter test` passes against the example widget.
- [ ] Both `soar_score_contest` and `soar_score_public` are able to import `soar_score_ui` (verify by adding the path dependency in a later integration ticket — at minimum, the package resolves standalone).
- [ ] Lint is clean.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md) — theme baseline.
- [005-scaffold-public-flutter-app.md](005-scaffold-public-flutter-app.md) — theme baseline.
- [014-setup-melos-workspace.md](014-setup-melos-workspace.md) — bulk command wiring (replaces rejected 002).

## Sources

- `AGENTS.md`
- `plan/implementation-plan.md`
