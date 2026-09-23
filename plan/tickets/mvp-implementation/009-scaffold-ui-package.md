# Ticket 009 — Scaffold `soar_score_ui` Package

- **Category:** Scaffold
- **Priority:** High
- **Status:** in-review

## Context

`packages/soar_score_ui` holds the shared Flutter UI components used by `soar_score_contest` and `soar_score_public`. Per `plan/implementation-plan.md`, both apps can share navigation constructs. This ticket sets up the package with a single example reusable widget (a card or app-bar component) so the dependency path into the two Flutter apps is proven.

## Decisions

- **Example widget:** `ScoreCard` in `widgets/` — presentational only (no state, no data access, per ticket 013's planned per-package rules for this package).
- **Theme scope:** shared tokens (`SoarScoreThemeTokens`) in `theme/` mirroring both app baselines (tickets 004/005); the apps keep their local theme files until a later integration ticket.
- **`components/` folder:** kept via a placeholder README, matching ticket 006's empty-folder convention.
- **`pubspec.lock` committed** for reproducible CI builds, matching tickets 003/006/008.

## Work Items

- [x] Create `packages/soar_score_ui` with a `pubspec.yaml` (Flutter SDK per ticket 001; path dependency on `soar_score_core`; `flutter` as a direct dependency).
- [x] Establish folder structure in `lib/`:
  - `widgets/` — reusable leaf widgets.
  - `components/` — larger composite components (cards, tables, forms).
  - `theme/` — shared theme extensions or tokens.
- [x] Add one reusable widget (e.g. `ScoreCard` or `SectionHeader`) in `widgets/`.
- [x] Add `lib/soar_score_ui.dart` exporting the public API.
- [x] Add one `flutter_test` widget test for the example widget, using `flutter_test` bindings.
- [x] Add `analysis_options.yaml` including `package:flutter_lints/flutter.yaml`.

## Acceptance Criteria

- [x] `flutter test` passes against the example widget. Verified: 5/5 passing (4 `ScoreCard` widget tests + 1 token unit test), Flutter 3.47.4 / Dart 3.13.3.
- [x] Both `soar_score_contest` and `soar_score_public` are able to import `soar_score_ui` (verify by adding the path dependency in a later integration ticket — at minimum, the package resolves standalone). Standalone resolution verified: `flutter pub get` resolves `soar_score_core` path dependency and all dev deps. App wiring deferred to a later integration ticket per the ticket text.
- [x] Lint is clean. Verified: `flutter analyze` → "No issues found!".

## Files changed

- `packages/soar_score_ui/pubspec.yaml` — new; name `soar_score_ui`, version 0.1.0, `publish_to: none`, SDK `>=3.13.0 <4.0.0`, Flutter `>=3.47.0` (ticket 001 pin); deps `flutter` (sdk) and path dep `soar_score_core`; dev deps `flutter_test` (sdk), `flutter_lints ^6.0.0`.
- `packages/soar_score_ui/pubspec.lock` — new; committed for reproducible CI builds (tickets 003/006/008 convention).
- `packages/soar_score_ui/.gitignore` — new; ignores `.dart_tool/`, `.packages`, `build/` (matches the other packages).
- `packages/soar_score_ui/analysis_options.yaml` — new; includes `package:flutter_lints/flutter.yaml`.
- `packages/soar_score_ui/lib/theme/soar_score_theme_tokens.dart` — new; `SoarScoreThemeTokens`: shared constants mirroring both app baselines (seed `0xFF006399`, primary, secondary `0xFF2D6A4F`, surface `0xFFF8FAFC`, high-viz amber `0xFFD97706`, card radius 12).
- `packages/soar_score_ui/lib/widgets/score_card.dart` — new; presentational `ScoreCard` (title, optional subtitle, optional trailing widget, optional body child, optional `onTap`); no state, no data access; theme-aware via `Theme.of(context)`.
- `packages/soar_score_ui/lib/components/README.md` — new; placeholder marking where larger composite components will live.
- `packages/soar_score_ui/lib/soar_score_ui.dart` — new; public API barrel exporting `theme/` and `widgets/`; the only import required by consumers.
- `packages/soar_score_ui/test/widgets/score_card_test.dart` — new; 4 `flutter_test` widget tests: renders title + subtitle + trailing + body, renders title only, `onTap` fires when provided, tapping without a handler is error-free. All import only the barrel.
- `packages/soar_score_ui/test/theme/soar_score_theme_tokens_test.dart` — new; 1 unit test asserting the tokens match the contest/public app baselines.
- `plan/tickets/mvp-implementation/009-scaffold-ui-package.md` — this ticket: status in-review, work items and acceptance criteria checked, decisions recorded, files changed, follow-ups.
- `plan/tickets/mvp-implementation/README.md` — index: 009 → In-Review.

## Follow-ups

- Add the path dependency on `soar_score_ui` to `soar_score_contest` and `soar_score_public` (later integration ticket per the acceptance criteria).
- Move the app theme files (`lib/theme/app_theme.dart` in both apps) onto `SoarScoreThemeTokens` when that integration runs (ticket 004's recorded follow-up).
- Populate `components/` with composite components (cards, tables, forms) — later workstream.
- Shared navigation constructs (both apps share them per `plan/implementation-plan.md`) — later workstream.
- Wire this package into the Melos workspace (ticket 014).
- Add a package README / per-package AGENTS.md if ticket 013 covers it.

## Dependencies

- [006-scaffold-core-package.md](006-scaffold-core-package.md)
- [004-scaffold-contest-flutter-app.md](004-scaffold-contest-flutter-app.md) — theme baseline.
- [005-scaffold-public-flutter-app.md](005-scaffold-public-flutter-app.md) — theme baseline.

## Sources

- `AGENTS.md`
- `plan/implementation-plan.md`
