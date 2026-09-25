# Ticket 022 — Continue offline flow on desktop landing page

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context
Add the "Continue offline" element visible only in the desktop application, allowing users to enter offline mode without an account. The web application must not show this element.

## Work Items
- [ ] Add "Continue offline" element to desktop-only view
- [ ] Implement offline mode entry without authentication requirement
- [ ] Add messaging about local vs published/synced contests
- [ ] Hide "Continue offline" element in web application

## Acceptance Criteria
- [ ] "Continue offline" element is visible on the desktop landing page
- [ ] Clicking it enters the application in offline mode without authentication
- [ ] Messaging explains offline contests remain local unless published or synced
- [ ] "Continue offline" element is not shown in the web application

## Dependencies
- [020-contest-landing-page-route.md](020-contest-landing-page-route.md) — landing page route and shell

## Sources
- `plan/ui/contest-administration/landing-page.md`