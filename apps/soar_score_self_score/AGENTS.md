# Self-Score App Agent Guide

Participant self-scoring web app: pilots enter their own scores for a contest.

## Structure

- `lib/main.dart`, `lib/app.dart` — entry point and app widget
- `lib/router.dart` — go_router routes (`/` home, `/scores` score entry)
- `lib/pages/` — one file per page
- `lib/api_client_provider.dart` — supplies the `soar_score_api` client to pages
- `test/` — widget and unit tests

## Boundaries

- **Must not do direct database access.** All data goes through the `soar_score_api` client.
- Depends on: `soar_score_api`, `soar_score_ui`. Do not add `soar_score_data` or `soar_score_sync`; the app is web-only and online.
- The Material theme (`SelfScoreAppTheme`) and shared tokens come from `soar_score_ui`.
- Keep each page and widget in its own file.

## Design Notes

- Score entry layout is tablet-first (`docs/adr/0002-score-entry-layout.md`).
- A PR that adds, renames or moves a route updates the page map in the root `AGENTS.md`.

## Testing

- Widget tests: `flutter test`
