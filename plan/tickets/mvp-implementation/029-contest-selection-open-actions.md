# Ticket 029 — Contest selection and open/continue/view actions

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context
Enable contest selection and state-dependent actions. Selecting a row activates it and enables actions. The primary action button changes based on contest state: "Open" for Created/Configuring, "Continue" for Ready/Running, "View" for Completed. PendingDelete opens a read-only deletion-status view; Deleted cannot be opened. Double-click and keyboard equivalents must work.

## Work Items
- [ ] Make contest rows selectable (click selects, enables actions)
- [ ] Implement state-dependent action button: Open / Continue / View
- [ ] Open navigation: Created/Configuring → contest configuration
- [ ] Continue navigation: Ready/Running → contest workspace, focused on latest group with scores
- [ ] View navigation: Completed → contest reports or read-only workspace
- [ ] Handle PendingDelete state: read-only deletion-status view
- [ ] Disable opening for Deleted state
- [ ] Add double-click behavior equivalent to primary action
- [ ] Ensure all actions are keyboard-accessible
- [ ] Loading more contests retains selection if contest remains in result set

## Acceptance Criteria
- [ ] Row selection works and enables action buttons
- [ ] Button text changes based on contest state per spec table
- [ ] Open button navigates to contest configuration for new/configuring contests
- [ ] Continue button navigates to contest workspace for ready/running contests
- [ ] View button navigates to read-only reports/workspace for completed contests
- [ ] PendingDelete shows read-only deletion status
- [ ] Deleted contests cannot be opened
- [ ] Double-click performs the primary action
- [ ] All actions available via keyboard
- [ ] Selection persists when more contests are loaded

## Dependencies
- [028-contest-list-pagination-empty-state.md](028-contest-list-pagination-empty-state.md)

## Sources
- `plan/ui/contest-administration/main-page.md`