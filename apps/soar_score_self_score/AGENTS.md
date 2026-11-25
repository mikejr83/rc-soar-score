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
- `integration_test/` — the E2E lifecycle journey (see Testing)

## Boundaries

- **Must not do direct database access.** All data goes through the `soar_score_api` client.
- Depends on: `soar_score_api`, `soar_score_ui`. Do not add `soar_score_data` or `soar_score_sync`; the app is web-only and online.
- The Material theme (`SelfScoreAppTheme`) and shared tokens come from `soar_score_ui`.
- Keep each page and widget in its own file.

## Guest session storage

On the web the guest session is an HttpOnly cookie (`__Host-soar_guest`, host-only on the API, Secure, SameSite=Lax) that the API sets when the invitation is resolved. The page cannot read it. The app sends it with every request (`session/api_http_client_web.dart` uses a credentialed browser client) and adds `X-Requested-With: soar-score-self-score`, which tells the API to use the cookie and is the API's CSRF check on writes. Browser storage keeps only display data (pilot, contest, role, expiry, in `session/`), which lets the router decide where to go and drop an expired session. A server answer of `session_invalid` clears it (`SessionEndedException`), and the pilot routes refuse another pilot's address. A body token (`GuestSession.token`, set when the request has no `X-Requested-With`: native clients and tests) is sent as a bearer token instead. The browser-storage store never writes a token, and drops any stored record that has one (sessions saved before the cookie), so the pilot opens their link again. There is no End session button while every session is a guest session: a guest can only get back in by scanning the QR code again (no email, no sign in yet), so the button only confused pilots. `session/end_session.dart` (`endGuestSession`, which calls `ApiClient.endGuestSession` and clears the local session even if the call fails) stays for signed-in accounts; bring a button back with them.

## Sign-in

`lib/auth/` holds the sign-in: `AuthSession` (the interface pages see), `Auth0Session` over an `Auth0Client` (Auth0's SPA SDK through `Auth0WebClient`, redirect flow, returns to the origin root; `restore()` starts right after the first frame is requested (never blocking it), waits for the deferred SDK script (and keeps watching for two minutes if it is late), and `signIn` retries it; `signOut` clears the session only after Auth0 logged out), `E2eAuthSession` (the `SOAR_SCORE_E2E` build only: signing in is instant, as the E2E server's seeded pilot) and `UnavailableAuthSession` (the default when no `AuthScope` is above a page, so a page tested alone shows no sign-in). Pages read it with `context.auth`. `ApiClient.accountTokenProvider` sends the Auth0 access token to the account routes only; the participant routes keep the guest token, because a bearer on them takes the place of the guest cookie. Settings are in `docs/auth0-setup.md`.

## Contests page

`/contests` (`pages/contests_page.dart`) is the signed-in pilot's list from `GET /account/participations` (`SelfScoreRepository.contests`): In progress, Invited and Completed sections (a section with no contest has no heading), a calm empty state, and a Sign in prompt when signed out (nothing is loaded then). A card opens the contest through `openContest` (`POST /account/participations/{id}/session`): the answer is stored as the guest session store's session and the router goes to the pilot overview, so everything after it is the guest-session path. A card shows Public results only when the server sent `public_results_url`. A 401 on the account routes is `SignedOutException` (the guest session is left alone); a contest that left the list is `ContestNotOnListException` and the list reloads. Dates arrive as `YYYY-MM-DD` in the contest's zone, because the app carries no zone database. Completed contests leave the list 24 hours after completion; the long-term history is #654.

## Design Notes

- The app is mobile-first: the first release is mobile web, viewed almost always on a phone, with native apps a future goal. Tablet and desktop layouts are very low priority. Official score entry in the contest app is the tablet-first screen (`docs/adr/0002-score-entry-layout.md`); self-scoring is not.
- A PR that adds, renames or moves a route updates the page map in the root `AGENTS.md`.

## Testing

- Widget tests: `flutter test`
- Integration (E2E) tests: `scripts/e2e-score.sh` (or `scripts/e2e-score.ps1`) builds the web app and runs `integration_test/` in headless Chrome against `apps/soar_score_server/tool/e2e_server.dart --profile server`, a test-only API server with invitations on (never deployed). Local only, not in CI. Chrome and chromedriver come from `scripts/e2e-setup.sh`. The contest app has its own script, `e2e-contest.sh`.
  - **One journey, phases as steps.** `integration_test/self_score_lifecycle_journey_test.dart` is the whole pilot story, split into phase files under `integration_test/journey/` (`phase_1_setup.dart` and so on; the `Journey` runner reports the failing step, route and screen texts, and `E2E_STOP_AFTER=<n>` ends the run after phase n). A new file runs a second app launch only when it cannot be a step.
  - **UI PRs extend the matching phase** with a step, in the same PR; they do not add a journey file. New or rewritten widgets use ARB strings.
  - **Set up through the API.** `integration_test/support/director_api.dart` creates the contest, draw and invitation links with plain HTTP calls (the E2E server acts as the director). Do not drive the contest app to set up.
  - **The browser cannot be reloaded.** A step opens a link with `router.go` (`openPath` in `phase_2_invitation.dart`), so "survives reload" is checked by leaving and reopening a page. Leave _sideways_: a page under the one just left (the pilot overview under the entry or group page) keeps its state, so go to `resultsPath` and back to see what the director changed meanwhile. The invitation route is keyed by the credential, so going straight from one link to another builds a new page; the journey relies on that.
  - **The form builds lazily.** Find a field through its label (`fieldFor`) and scroll with `scrollTo`; never by position.
  - **The invitation clock.** `POST /__e2e/advance-clock?hours=N` on the E2E server moves link expiry forward and never back, so the expiry steps are the last phase (7). Only the invitation service sees this clock.
  - **The signed-in pilot** is the E2E server's seeded account (Penny Pilot, verified email): a request with `Authorization: Bearer e2e-pilot` acts as her, and `POST /__e2e/pilot-account-link` (`{participation_id, state: candidate|confirmed}`, after the director issued the invitation through the API) offers her a contest as an "Is this you?" match or links it. The app's sign-in has no Auth0 round trip in E2E.
  - **Director steps** (`SeededContest.scoreAsDirector`, `.action('complete' | 'hideResults' | ...)`) go through the API like the contest app would.
  - A run fails on any error the framework logged, even if every step passed. The `Journey` also posts each one to the server log as `[E2E] FlutterError: ...`, which is how to read them on the web.
