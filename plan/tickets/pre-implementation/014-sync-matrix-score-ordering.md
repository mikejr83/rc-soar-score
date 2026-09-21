# Ticket 014 — Offline Sync: Matrix Change + Score Entry Ordering

- **Category:** Offline Sync
- **Priority:** High
- **Status:** Open

## Context

If a matrix revision is published (new round) while offline score entries are queued, the sync order is unclear.

## Questions

1. Can offline score entries reference flight groups that do not yet exist on the server (i.e., created by a locally-drawn round)?
2. What is the sync order when both a matrix revision and score entries are pending — matrix first, then scores, or scores first, then matrix?
3. If a score entry references a group id that the server doesn't recognize, is it rejected, queued, or matched by a different key?
4. How does the client handle a matrix revision that changes group membership after scores were entered for the old grouping?

## Decisions Needed

- Sync ordering rules for matrix revisions vs. score entries.
- How offline-created groups are reconciled with server state.

## Sources

- `plan/architecture-requirements/matrix-draw.md`
- `plan/architecture-requirements/data/scores-and-results.md`
