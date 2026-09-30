# Ticket 033 — Sync action on home page

- **Category:** UI
- **Priority:** Medium
- **Status:** Open

## Context
Implement the sync action on the contest administration home page. The sync button appears when the user is authenticated and a remote connection is available. This ticket covers only the sync button and its basic state; the actual sync workflow and connectivity monitoring are out of scope.

## Work Items
- [ ] Add sync button to the home page
- [ ] Display sync button only when authenticated and remote connection is available
- [ ] Implement basic click behavior as a stub for the sync operation
- [ ] Style button appropriately per layout requirements

## Acceptance Criteria
- [ ] Sync button is visible when the user is authenticated and online
- [ ] Sync button is hidden when not authenticated or offline
- [ ] Clicking the button triggers the sync operation stub
- [ ] Button is styled and positioned per design requirements

## Dependencies
- [027-contest-home-route-shell.md](027-contest-home-route-shell.md)

## Sources
- `plan/ui/contest-administration/main-page.md`