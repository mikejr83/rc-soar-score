# Ticket 030 — Create new contest navigation

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context
Implement the "Create contest" action on the home page. When the contest director clicks this, navigate to the contest creation wizard. This ticket covers the button and navigation only; the wizard itself is out of scope.

## Work Items
- [ ] Add "Create contest" button to the home page
- [ ] Implement navigation to the contest creation wizard route on click
- [ ] Ensure button is always available (not dependent on selection)
- [ ] Position button appropriately per design

## Acceptance Criteria
- [ ] "Create contest" button is visible on the home page
- [ ] Clicking the button navigates to the contest creation wizard
- [ ] Button is always enabled regardless of contest selection
- [ ] Button position and style match layout requirements

## Dependencies
- [027-contest-home-route-shell.md](027-contest-home-route-shell.md)

## Sources
- `plan/ui/contest-administration/main-page.md`