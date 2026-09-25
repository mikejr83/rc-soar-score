# Ticket 023 — Persistent application status area

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context
Implement the persistent status area that displays connectivity, sync, and contest-state information across the application shell. This is required for both online and offline contexts.

## Work Items
- [ ] Implement status bar in persistent shell
- [ ] Display internet connectivity status
- [ ] Display remote API connectivity and last successful connection time
- [ ] Display synchronization state (last sync, unsent mutations, remote revision, conflicts)
- [ ] Display selected contest lifecycle and participant-scoring state
- [ ] Display round/group scoring information when relevant
- [ ] Make status items selectable to open relevant details/actions

## Acceptance Criteria
- [ ] Internet connectivity status is displayed
- [ ] Remote API connectivity status and last connection time are displayed
- [ ] Synchronization state (last sync, unsent mutations, remote revision, conflicts) is displayed
- [ ] Selected contest lifecycle and participant-scoring state are displayed when active
- [ ] Round/group scoring information is displayed when relevant
- [ ] Selecting a status item opens relevant details or action

## Dependencies
- [020-contest-landing-page-route.md](020-contest-landing-page-route.md) — landing page route and shell

## Sources
- `plan/ui/contest-administration/README.md`
- `plan/ui/contest-administration/offline-ui.md`