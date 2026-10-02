# Ticket 022 — Continue offline flow on desktop landing page

- **Category:** UI
- **Priority:** High
- **Status:** in-review

## Context

Add the "Continue offline" element visible only in the desktop application, allowing users to enter offline mode without an account. The web application must not show this element.

## Work Items

- [x] Add "Continue offline" element to desktop-only view
- [x] Implement offline mode entry without authentication requirement
- [x] Add messaging about local vs published/synced contests
- [x] Hide "Continue offline" element in web application

## Acceptance Criteria

- [x] "Continue offline" element is visible on the desktop landing page
- [x] Clicking it enters the application in offline mode without authentication
- [x] Messaging explains offline contests remain local unless published or synced
- [x] "Continue offline" element is not shown in the web application

## Follow-ups

- Implement the full contest-selection page described in `plan/ui/contest-administration/main-page.md`; this ticket adds only the offline entry stub.

## Files Changed

- `apps/soar_score_contest/lib/main.dart`
- `apps/soar_score_contest/lib/pages/bootstrap_failure_page.dart`
- `apps/soar_score_contest/lib/pages/contest_selection_stub_page.dart`
- `apps/soar_score_contest/lib/pages/landing_page.dart`
- `apps/soar_score_contest/lib/platform/native_bootstrap.dart`
- `apps/soar_score_contest/lib/platform/web_bootstrap.dart`
- `apps/soar_score_contest/lib/router.dart`
- `apps/soar_score_contest/test/bootstrap_failure_page_test.dart`
- `apps/soar_score_contest/test/widget_test.dart`
- `apps/soar_score_contest/lib/connectivity_provider.dart` (formatter-only)
- `apps/soar_score_contest/lib/services/connectivity/app_connectivity.dart` (formatter-only)
- `apps/soar_score_contest/lib/services/connectivity/internet_probe.dart` (formatter-only)
- `apps/soar_score_contest/lib/widgets/connectivity_indicator.dart` (formatter-only)
- `apps/soar_score_contest/lib/widgets/contest_shell.dart` (formatter-only)
- `apps/soar_score_contest/lib/widgets/contest_status_bar.dart` (formatter-only)
- `apps/soar_score_contest/test/landing_connectivity_test.dart` (formatter-only)
- `apps/soar_score_contest/test/services/connectivity/app_connectivity_test.dart` (formatter-only)
- `apps/soar_score_contest/test/widgets/connectivity_indicator_test.dart` (formatter-only)
- `packages/soar_score_core/lib/enums/connectivity_status.dart` (formatter-only)
- `packages/soar_score_core/lib/enums/enums.dart` (formatter-only)
- `packages/soar_score_core/lib/soar_score_core.dart` (formatter-only)

## Dependencies

- [020-contest-landing-page-route.md](020-contest-landing-page-route.md) — landing page route and shell

## Sources

- `plan/ui/contest-administration/landing-page.md`
