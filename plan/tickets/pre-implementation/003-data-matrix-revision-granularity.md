# Ticket 003 — Matrix Revision Granularity

- **Category:** Data Model / Schema
- **Priority:** High
- **Status:** Open

## Context

A matrix revision is described as immutable. But when a pilot moves mid-round, the draw changes. It is unclear whether that produces a new revision or an amendment, and how `flight_group` references the governing revision.

## Questions

1. When a pilot is moved mid-round, is a new matrix revision created, or is the existing revision amended?
2. If a new revision is created, how does the revision counter and the `matrix` relation on `flight_group` handle it — does each flight group point to the revision that governed it at the time of the flight?
3. Can a contest have multiple matrix revisions simultaneously active (e.g., one for rounds 1–3, a new one for rounds 4+ after a re-draw)?
4. What is the retention policy for superseded matrix revisions?

## Decisions Needed

- Revision model (immutable full snapshots vs. amendment log).
- How `flight_group` links to the matrix revision that produced it.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§7.2 Matrix Revision Entity Contract)
- `plan/architecture-requirements/data/contest.md`
