# Ticket 021 — Sign in and Create account stubs on landing page

- **Category:** UI
- **Priority:** High
- **Status:** in-review

## Context

Add the Sign in and Create account UI elements to the landing page. Actual authentication flows are out of scope for this phase; these will be stubbed with notifications indicating the work is not yet complete.

## Work Items

- [x] Add "Sign in" button/element to landing page
- [x] Add "Create account" button/element to landing page
- [x] Implement stub behavior showing notification when clicked
- [x] Position and style elements according to layout requirements

## Acceptance Criteria

- [x] "Sign in" element is visible on the landing page
- [x] "Create account" element is visible on the landing page
- [x] Clicking Sign in shows notification that workflow is not yet complete
- [x] Clicking Create account shows notification that workflow is not yet complete
- [x] Elements are positioned and styled per layout requirements
- [x] Buttons are disabled when there is no internet connectivity.
- [x] Sign-in should be disabled when no api connectivity per the connectivity functionality already built into the app.

## Implementation Notes

- Both buttons require available internet connectivity; Sign in additionally requires an available API connection. Unknown and checking states remain disabled.
- Button availability updates when the connectivity monitor reports state changes. Enabled buttons retain their existing not-wired-up dialogs.

## Files Changed

- `apps/soar_score_contest/lib/pages/landing_page.dart`
- `apps/soar_score_contest/test/landing_connectivity_test.dart`
- `plan/tickets/mvp-implementation/021-sigin-create-account-stubs.md`

## Verification

- Focused `landing_connectivity_test.dart`: passed (4 tests).
- `scripts/verify.ps1`: failed on format checks for other modified files and three `contest_shell_test.dart` cases reporting a landing-page `RenderFlex` overflow. The touched Dart files have no analyzer diagnostics.
- No acceptance criteria remain unimplemented; the full verification gate remains outstanding.

## Follow-ups

- Investigate the landing-page `RenderFlex` overflow in the shell test context; this is outside the connectivity-gating change.

## Dependencies

- [020-contest-landing-page-route.md](020-contest-landing-page-route.md) — landing page route and shell

## Sources

- `plan/ui/contest-administration/landing-page.md`
