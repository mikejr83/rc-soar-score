# Self-Score App Agent Guide

Participant self-scoring web app: pilots enter their own scores for a contest.

## Structure

- `lib/main.dart`, `lib/app.dart` — entry point and app widget
- `lib/router.dart` — go_router routes per `plan/ui/participant-scoring/participant-scoring.md`; see the self-score page map in the root `AGENTS.md`
- `lib/pages/` — one file per page
- `lib/widgets/` — page widgets; `landing_control.dart` picks sheet or autocomplete by landing-table size
- `lib/data/` — `SelfScoreRepository` (what pages read), its API-backed and sample implementations and `SelfScoreScope`; pages never read `SampleData` or the API client directly
- `lib/models/`, `lib/services/` — view models the pages show, and pure logic (time parsing, landing search)
- `lib/api_client_provider.dart` — supplies the `soar_score_api` client to pages
- `test/` — widget and unit tests

## Boundaries

- **Must not do direct database access.** All data goes through the `soar_score_api` client.
- Depends on: `soar_score_api`, `soar_score_ui`. Do not add `soar_score_data` or `soar_score_sync`; the app is web-only and online.
- The Material theme (`SelfScoreAppTheme`) and shared tokens come from `soar_score_ui`.
- Keep each page and widget in its own file.

## Guest session storage

The guest session token is kept in browser local storage (`session/`), as agreed for the first field release (#143 comment, 2026-10-18: keep the storage layer thin and swappable). Any script on the page can read it, so the page loads no third-party scripts, and the token is only as strong as the server's expiry and revocation: the server checks it on every request, the app drops a session that has expired locally or that the server calls ended (`SessionEndedException`), and the pilot routes refuse another pilot's address. Moving to an HttpOnly cookie set by the resolve endpoint is a server and hosting change (the API is on another origin) and is tracked with the account work, not done here.

## Design Notes

- The app is mobile-first: the first release is mobile web, viewed almost always on a phone, with native apps a future goal. Tablet and desktop layouts are very low priority. Official score entry in the contest app is the tablet-first screen (`docs/adr/0002-score-entry-layout.md`); self-scoring is not.
- A PR that adds, renames or moves a route updates the page map in the root `AGENTS.md`.

## Testing

- Widget tests: `flutter test`
