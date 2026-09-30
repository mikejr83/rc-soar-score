# Ticket 032 — Contest archive filter

- **Category:** UI
- **Priority:** Medium
- **Status:** Open

## Context
Provide an explicit archive filter on the contest list. Archived contests are excluded by default, but the director can toggle to view them. This filter works alongside the regular contest list and pagination.

## Work Items
- [ ] Add archive filter toggle/checkbox to the contest administration page
- [ ] Default state excludes archived contests
- [ ] When enabled, include archived contests in the list
- [ ] Ensure pagination works correctly with the filter
- [ ] Retain filter state across page loads if appropriate

## Acceptance Criteria
- [ ] Archive filter control is visible on the page
- [ ] Default view excludes archived contests
- [ ] Enabling the filter includes archived contests in the list
- [ ] Pagination continues to work with filtered results
- [ ] Filter state is preserved appropriately

## Dependencies
- [028-contest-list-pagination-empty-state.md](028-contest-list-pagination-empty-state.md)

## Sources
- `plan/ui/contest-administration/main-page.md`