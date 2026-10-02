# Ticket 024 — Landing page loading, error, and unavailable states

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context

The landing page must handle multiple states: loading while initializing, identity-provider unavailable, and offline-store unavailable. These states must be clearly communicated to the user.

## Work Items

- [ ] Implement loading state shown during page initialization
- [ ] Implement identity-provider unavailable error state
- [ ] Implement offline-store unavailable error state with recovery action
- [ ] Ensure error states include reason and recovery actions

## Acceptance Criteria

- [ ] Loading state is shown while the page is initializing
- [ ] Error state is shown when identity provider is unavailable
- [ ] Error state is shown when offline local store cannot be opened
- [ ] Offline-store error includes reason and recovery action
- [ ] User is not taken into application with partial data

## Dependencies

- [020-contest-landing-page-route.md](020-contest-landing-page-route.md) — landing page route and shell

## Sources

- `plan/ui/contest-administration/landing-page.md`
