# Ticket 026 — Accessibility, responsive layout, and locale on landing page

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context

Ensure the landing page and shell meet all accessibility, responsive, and locale requirements. State must not be communicated by color alone, and the layout must support varied display sizes and font settings.

## Work Items

- [ ] Add labels to all controls
- [ ] Add keyboard access to all interactive elements
- [ ] Add visible focus indicators
- [ ] Add screen-reader state announcements
- [ ] Implement locale formatting for dates, times, decimals, numbers
- [ ] Ensure touch targets are large enough for mobile use
- [ ] Ensure state is not communicated by color alone (text, icon, or shape)
- [ ] Verify responsive layout for tablet and larger screens

## Acceptance Criteria

- [ ] All controls have labels, keyboard access, visible focus indicators, screen-reader state announcements
- [ ] Dates, times, decimal separators, and number formatting follow user's locale
- [ ] Touch targets are large enough for mobile use
- [ ] State is not communicated by color alone; every status includes text, icon or shape
- [ ] Layout is responsive for tablet and larger screens

## Dependencies

- [020-contest-landing-page-route.md](020-contest-landing-page-route.md) — landing page route and shell

## Sources

- `plan/ui/contest-administration/README.md`
