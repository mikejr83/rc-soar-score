# Ticket 032 — UI: Offline-Capable Pages

- **Category:** UI / UX
- **Priority:** Medium
- **Status:** Decided (see [#81](https://github.com/mikejr83/rc-soar-score/issues/81))

## Context

The plan states offline mode exists, but does not specify which pages are available offline.

## Questions

1. Is the score-entry screen the only offline-capable page, or can a helper also view the matrix, standings, and group history offline?
2. Can a helper view the current round's group assignments offline?
3. Can a pilot view their own previous scores offline?
4. Is there an offline queue indicator (e.g., "5 scores pending sync")?
5. How does the UI indicate when data is stale (e.g., "last synced 10 minutes ago")?

## Decisions Needed

- The list of offline-capable pages.
- The UX for indicating sync status and data staleness.

## Sources

- `plan/ui/participant-scoring/`
- `plan/architecture-requirements/` (offline sync documentation)
