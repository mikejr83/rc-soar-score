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

`lib/auth/` holds the sign-in: `AuthSession` (the interface pages see), `Auth0Session` over an `Auth0Client` (Auth0's SPA SDK through `Auth0WebClient`, redirect flow, returns to the origin root; `restore()` starts right after the first frame is requested (never blocking it), waits for the deferred SDK script (and keeps watching for two minutes if it is late), and `signIn` retries it; `signOut` clears the session only after Auth0 logged out), `E2eAuthSession` (the `SOAR_SCORE_E2E` build only: signing in is instant, as the E2E server's seeded pilot) and `UnavailableAuthSession` (the default when no `AuthScope` is above a page, so a page tested alone shows no sign-in). Pages read it with `context.auth`. `ApiClient.accountTokenProvider` sends the Auth0 access token to the account routes only; the participant routes keep the guest token, because a bearer on them takes the place of the guest cookie. On an invitation link, Sign in passes `returnTo` (the link's path) as Auth0 app state; `Auth0WebClient` hands it back only when it is a path inside the app, and the landing page goes back to it once after the restore finishes (`takeReturnTo`). A signed-in pilot sees "Continue as <name>" on the link, which calls `claimInvitation` (`POST /account/invitation-claims`): the account is linked, the guest entries are claimed server-side, and the session answered acts as the account. "Continue as guest" stays beside it. Settings are in `docs/auth0-setup.md`. A claim answered 401 offers Sign in again (back to the link); only a 409 `already_linked` says the pilot is held by another account, any other claim failure reads as a failure to retry. Pages only a signed-in pilot can use (contests, details, account) sit in `SignedInGate`: a loading state while the sign-in is being restored (never a blank page or a sign-in prompt flash), the page when signed in, the landing page (or the contests page's own prompt) when the restore finished signed out. `AuthSession.detailsChecked` makes the landing page's look for a directory entry happen once per sign-in, not on every visit.

### Auth0 SDK script

`web/index.html` loads the Auth0 SPA SDK from `web/auth0-spa-js-<version>.production.js` (the `dist/auth0-spa-js.production.js` file of the npm package `@auth0/auth0-spa-js`, MIT licence in `web/auth0-spa-js-LICENSE.txt`), not from a CDN, at an exact version with a `sha384` `integrity` attribute. To update: `npm pack @auth0/auth0-spa-js@<version>`, unpack it, copy the file in under the new name (delete the old one, and update the name in `index.html` and `_headers`), and set `integrity` to `sha384-` plus `openssl dgst -sha384 -binary <file> | openssl base64 -A`. Never use a floating version.  The contest app's `web/` holds the same file the same way; update both together.

## Contests page

`/contests` (`pages/contests_page.dart`) is the signed-in pilot's list from `GET /account/participations` (`SelfScoreRepository.contests`): In progress, Invited and Completed sections (a section with no contest has no heading), a calm empty state, and a Sign in prompt when signed out (nothing is loaded then). A card opens the contest through `openContest` (`POST /account/participations/{id}/session`): the answer is stored as the guest session store's session and the router goes to the pilot overview, so everything after it is the guest-session path. A card shows Public results only when the server sent `public_results_url`. A 401 on any account route (the list, history, open, candidates, directory entry and links) is `SignedOutException` (the guest session is left alone), never "could not reach the server": the page says the sign-in ended and offers Sign in again (`auth/sign_in_again.dart`); a contest that left the list is `ContestNotOnListException` (only a 404 with the server's `link_not_found` code, so a proxy's 404 page is not mistaken for it) and the list reloads. Dates arrive as `YYYY-MM-DD` in the contest's zone, because the app carries no zone database. Completed contests leave the list 24 hours after completion; the long-term history is #654.

## Is this you?

`/details` (`pages/details_page.dart`) is where a signed-in pilot sets what contest directors may find (#652): name (prefilled from the account), "Let contest directors find me" and "Keep my email private" (both ticked by default) and optional FAI number, national ID, club and country, saved through `SelfScoreRepository.saveOwnDirectory` (`PUT /account/directory-entry`). Continuing always makes the entry, listed or not. The landing page sends a signed-in pilot whose `ownDirectory()` has no entry here once (not when `takeReturnTo` brings them back to an invitation link, and a failed look leaves them where they are); `widgets/directory_prompt_card.dart` on the contests page asks the same pilot otherwise. The email is never on these pages: the server only says one is available.

`widgets/link_candidates_section.dart` loads the signed-in account's matches itself (`SelfScoreRepository.linkCandidates`, `GET /account/link-candidates`), so a failure there never takes the contests page down; it shows one `IsThisYouCard` per pilot. Yes calls `confirmLinkCandidate` and tells the page to load its list again (the link brings contests); Not me calls `declineLinkCandidate`, which the server remembers. Only 409 `already_linked` (another account holds the pilot) and 404 `link_not_found` (not a match any more) are a `LinkCandidateGoneException`: the card says why and goes, with both buttons off meanwhile. Any other answer (a 409 `invitations_not_available` or `backend_only` too) keeps the card so the answer can be resent. The account routes use the account token, never the guest token, and their failures never end the guest session. Dates on the card are the contest's first and last day in its own zone, as the server names them (`start_date`, `end_date`), formatted by the same `services/contest_dates.dart` as the contests list; the app carries no zone database and never converts instants. The section sits in the signed-in list only (the signed-out page has none), so a guest never calls the account routes. A renewal failure that is not an Auth0 rejection (`auth/renewal_policy.dart`) keeps the pilot signed in so Try again can work.

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
