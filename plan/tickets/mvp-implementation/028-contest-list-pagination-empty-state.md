# Ticket 028 — Contest list with pagination and empty state

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context

Build the primary contest list on the home page. Show the ten most recent eligible contests, with "Show all contests" to load the next 50 per page. Each row displays contest name, date range, venue/location, last activity, and status values. Provide an empty state that links to creating a contest.

## Work Items

- [ ] Implement contest list widget showing 10 contests initially
- [ ] Add "Show all contests" link/button when more than 10 eligible contests exist
- [ ] Load next 50 records per page on "Show all" interaction
- [ ] Render each contest row with: name, date range, venue/location, last activity, status
- [ ] Show an empty state with "Create contest" when no contests exist
- [ ] Exclude archived contests by default; exclude deleted contests entirely

## Acceptance Criteria

- [ ] First load shows at most 10 contests, ordered by most recent activity
- [ ] "Show all contests" appears when >10 non-archived contests exist
- [ ] Clicking "Show all" loads next 50 records and preserves existing rows
- [ ] Each row displays contest name, date range, venue, last activity, and status
- [ ] Empty state displays only when the list is empty and links to create
- [ ] Archived contests are hidden by default; deleted contests never appear

## Dependencies

- [027-contest-home-route-shell.md](027-contest-home-route-shell.md)

## Sources

- `plan/ui/contest-administration/main-page.md`
