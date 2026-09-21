# Ticket 001 — Team Membership Cardinality

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** Open

## Context

The data model does not state whether a pilot can belong to multiple teams within a single contest. This matters for the draw engine (team protection), re-flight team-protection, and team totals.

## Questions

1. Can a pilot belong to more than one team in a single contest?
2. If yes, how does re-flight team-protection work — a re-flight pilot cannot be placed with a teammate, but which team membership applies?
3. How are team totals computed when a pilot is on multiple teams?
4. Does the draw's team-protection constraint (pilots of the same team never share a group) need to consider all of a pilot's team memberships?

## Decisions Needed

- Cardinality rule for pilot→team membership (one-to-many vs. one-to-one).
- How multi-team membership is resolved for team-protection, re-flight placement, and team scoring.

## Sources

- `plan/architecture-requirements/data/contest.md`
- `plan/architecture-requirements/data/disciplines-and-configuration.md`
- `plan/business-requirements/disciplines/f5j.md` (Re-Flights)
