# Ticket 013 — Offline Sync: Score Edit Conflict Resolution

- **Category:** Offline Sync
- **Priority:** High
- **Status:** Open

## Context

Two helpers on different devices may edit the same score in the same group while offline. The conflict resolution strategy is not defined.

## Questions

1. When two offline edits conflict on the same score, is it last-write-wins, or is there a field-level merge?
2. Which fields are mergeable (e.g., time vs. landing vs. late-landing flag)?
3. How is the conflict surfaced to the user — a notification, a merge prompt, or a silent overwrite?
4. What is the tie-breaker when two edits have the same timestamp (e.g., device id, user id)?

## Decisions Needed

- Conflict resolution strategy (last-write-wins vs. field merge).
- The conflict notification UX.

## Sources

- `plan/architecture-requirements/` (offline sync documentation)
- `plan/ui/participant-scoring/`
