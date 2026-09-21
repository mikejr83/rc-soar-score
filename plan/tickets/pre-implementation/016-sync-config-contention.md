# Ticket 016 — Offline Sync: Concurrent Config Edits

- **Category:** Offline Sync
- **Priority:** Low
- **Status:** Open

## Context

Two directors on different devices may edit the same contest configuration concurrently. The conflict resolution is not specified.

## Questions

1. Is config editing optimistic-concurrency (version check) or last-write-wins?
2. If a conflict is detected, is the user prompted to merge, or is one edit silently discarded?
3. Can two devices both create a new configuration revision, and how is the sequence number resolved?
4. Does a config edit conflict also affect the calculation revision sequence?

## Decisions Needed

- Concurrency model for config revisions.
- Conflict resolution UX for directors.

## Sources

- `plan/architecture-requirements/data/disciplines-and-configuration.md`
