# Ticket 015 — Offline Sync: Partial Failure Mid-Sequence

- **Category:** Offline Sync
- **Priority:** Medium
- **Status:** Open

## Context

The atomicity boundary for offline sync is not defined. If a group of scores is being synced and one fails, the recovery behavior is unclear.

## Questions

1. What is the atomicity boundary — is a group's worth of scores one unit, or is each score a unit?
2. If score 5 of 10 in a group fails, does the client resume from score 5 or restart the whole group?
3. Are partially-synced groups visible on the public site, or are they held until the full group is synced?
4. How does the client track which scores have been synced (local offset, server ack per score)?

## Decisions Needed

- Atomicity unit for score sync.
- Resume-on-failure behavior.
- Visibility rules for partially-synced groups.

## Sources

- `plan/architecture-requirements/` (offline sync documentation)
