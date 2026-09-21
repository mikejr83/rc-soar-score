# Ticket 002 — Lane Assignment: Derived or Independent Revision

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** Open

## Context

GliderScore assigns lanes after groups are finalized. It is unclear whether the draw stores lane assignments as part of the same matrix revision, or as a separate revision that can be re-optimized independently (e.g., when a pilot drops out mid-round).

## Questions

1. Are lane assignments stored within the matrix revision, or as a separate revision?
2. If separate, can lanes be re-optimized without invalidating the group assignments?
3. When a pilot drops out mid-round, is the lane assignment regenerated for the remaining pilots?
4. How does the `matrix` relation on `flight_group` reference lane assignments — by revision id or embedded?

## Decisions Needed

- Storage model for lane assignments (embedded vs. separate revision).
- Re-optimization rules when the pilot set changes mid-contest.

## Sources

- `plan/architecture-requirements/matrix-draw.md`
- `research/glidercore-draw/README.md` (§5 recommendation 5)
- `plan/architecture-requirements/data/scores-and-results.md`
