# Ticket 001 — Team Membership Cardinality

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** Ready

## Context

Pilot→team membership cardinality is not stated in the data model. `participants.md` describes the participation link as carrying a singular "team reference, if teams are enabled", which leans toward one team per pilot, but this was never made explicit. This affects the draw engine (team protection), re-flight team-protection, and team totals.

## Decisions

1. **Pilot→team membership is one-to-one.** A pilot (participant with the `Pilot` role) belongs to at most one team within a single contest; most participation links may have no team. This matches the singular "team reference" on the participation link in `participants.md`.
2. **Re-flight draw exclusion uses the pilot's current team membership.** When a re-flight group is formed by random draw, "competitors from the same team are excluded" means the members of the re-flight pilot's single current team (at the time of the re-flight draw) are excluded from the candidate pool. The re-flight pilot themselves is the subject of the re-flight and is not a candidate in their own re-flight draw. Team membership is fixed for a matrix revision, so "current" membership is well-defined and does not drift during a contest.
3. **Seeded-draw team-protection fallback is out of scope.** Whether seeded man-on-man and team protection can be combined, and what happens when a rank-displacement swap fails, is tracked in ticket 027 (`027-matrix-seeded-team-protection.md`) and is not part of this ticket.

## Remaining Questions

(None.)

## Decisions Needed

(All resolved.)

## Acceptance Criteria

- [ ] Participation link schema enforces at most one team reference per pilot (one-to-one).
- [ ] Attempting to assign a pilot who is already on a team to another team is rejected or requires an explicit membership-change flow.
- [ ] Team protection in the draw engine uses each pilot's single current team membership.
- [ ] Re-flight draw exclusion excludes the members of the re-flight pilot's single current team from the candidate pool; the re-flight pilot is not a candidate in their own re-flight draw.
- [ ] Team totals are computed from each team's own eligible pilot contest totals (using the already-rounded/truncated pilot totals, per ticket 006), with no cross-team double counting possible (guaranteed by one-to-one membership).
- [ ] Membership change after a matrix exists triggers the redraw flow described in `contest-configuration.md` (teams locked once a matrix exists; new pilots may be added randomly without a redraw).
- [ ] Seeded-mode team-protection fallback behavior is defined and tested per ticket 027.

## Sources

- `plan/architecture-requirements/data/contest.md`
- `plan/architecture-requirements/data/disciplines-and-configuration.md`
- `plan/business-requirements/disciplines/f5j.md` (Re-Flights)

