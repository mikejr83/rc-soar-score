# Ticket 031 — Delete and delisting contests

- **Category:** UI
- **Priority:** High
- **Status:** Open

## Context

Implement delete and delisting actions for selected contests. Unpublished local contests can be deleted with confirmation. Published contests use "Request delisting" which starts a pending-delete workflow. Show appropriate confirmations and handle server responses including rejection reasons.

## Work Items

- [ ] Add delete/delisting action button, enabled only when contest is selected and deletion rules allow it
- [ ] Show "Delete" for unpublished local contests
- [ ] Show "Request delisting" for contests published at least once
- [ ] Implement delete confirmation dialog stating local data removal (not recoverable)
- [ ] Implement delisting confirmation explaining pending-delete workflow and no immediate erase
- [ ] Call appropriate API/service for deletion or delisting request
- [ ] Show server rejection reason and leave contest unchanged on failure
- [ ] Update UI to show PendingDelete status when delisting is accepted
- [ ] Remove contest from list after successful deletion
- [ ] Block editing, scoring, publishing for PendingDelete contests

## Acceptance Criteria

- [ ] Delete/delisting button is only enabled with an eligible contest selected
- [ ] "Delete" appears for unpublished contests, "Request delisting" for published
- [ ] Delete confirmation dialog warns about permanent local data loss
- [ ] Delisting confirmation explains pending-delete workflow
- [ ] Server rejection shows specific reason; contest remains unchanged
- [ ] Accepted delisting shows PendingDelete status
- [ ] Successful deletion removes contest from list
- [ ] PendingDelete contests block editing and scoring operations

## Dependencies

- [029-contest-selection-open-actions.md](029-contest-selection-open-actions.md)

## Sources

- `plan/ui/contest-administration/main-page.md`
