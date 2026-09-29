# Ticket 002 — Lane Assignment: Derived or Independent Revision

- **Category:** Data Model / Schema
- **Priority:** Medium
- **Status:** Ready
- **Decision:** Lanes are embedded in the matrix revision and never change independently of a draw. A pilot move creates a `Moved` assignment record (which always carries a lane) but does not regenerate the matrix or re-optimize lanes.

## Context

Lanes are a pilot-facing indicator used by the contest director to avoid a pilot monopolizing a single flight line station (assumed to give an advantage). Lanes have no scoring role and are not tracked for scoring purposes.

GliderScore assigns lanes after groups are finalized, which suggested lanes might be stored as a separate, independently re-optimizable revision. That is not the case here: lane randomization happens as part of the draw itself, so there is no operation that changes lanes without also changing (or re-drawing) the matrix.

## Questions (resolved)

1. **Are lane assignments stored within the matrix revision, or as a separate revision?**
   Stored within the matrix revision. The lane assignment is part of the revision's content alongside rounds, groups, and assignments — consistent with `data/matrix-and-assignments.md` ("A matrix revision records … rounds, groups, lanes …").
2. **Can lanes be re-optimized without invalidating the group assignments?**
   No. There is no lane-only revision. The only operations that produce lane assignments are:
   - **Initial draw / redraw** — groups and lanes are randomized together within one matrix revision.
   - **Pilot move** — the director chooses the destination group when performing the move (how the destination lane value on the resulting `Moved` record is set is an open follow-up, since assignments always store a lane). The matrix revision is not regenerated, and no re-optimization of the source or target group's lanes is triggered — the director may consider lane impacts as part of deciding where to place the pilot. (This matches `move-pilot.md`: a move "does not delete or rewrite" anything and "retain[s] the prior assignment and the reason, actor, time, and contest/matrix revision for the move.")
3. **When a pilot drops out mid-round, is the lane assignment regenerated?**
   No. A drop-out (retirement) does not regenerate the matrix or lanes. If the director wants new lanes, they perform an explicit re-draw, which creates a new matrix revision (see ticket 003 for revision granularity and ticket 021 for mid-contest re-draw rules).
4. **How does the `matrix` relation on `flight_group` reference lane assignments — by revision id or embedded?**
   Lanes are embedded in the revision. The `matrix` relation on `flight_group` references the matrix revision by `matrixRevisionId` (one revision id per group, since each group belongs to exactly one round of one revision); the lane is a stored field on each assignment within that revision, not a separate referenced object.

## Decisions

- **Storage model:** Lane assignments are embedded content of the matrix revision — the same revision that stores rounds, groups, seed, and fairness summary. There is no independent lane revision.
- **Independence:** Lanes are never re-optimized in isolation. "Re-optimization" is only a side effect of a new draw/redraw.
- **Mid-round changes:** A pilot move does not regenerate the matrix; no lane re-optimization is triggered automatically. The director may consider the impact on the source/target groups' lane balance when choosing the destination. A pilot drop-out does not regenerate lanes; an explicit re-draw is the only other lane-change path.
- **Follow-up (unblocks UI work):** `move-pilot.md` does not specify how the `Moved` assignment's lane value is set. Decide whether the move dialog exposes an explicit lane picker (director choice, defaulting to the moved pilot's previous lane) or the application auto-assigns (e.g., lowest free lane in the target group). Small, low-risk; not blocking the data model.
- **Scoring relevance:** Lanes have no role in scoring, normalization, or calculation. They are informational for pilots and the director only. (The `Lane Uniformity Index` in `matrix-draw.md` §7.1 remains a report-only metric on the revision's fairness summary.)

## Acceptance criteria

- The data model stores the lane as part of the assignment content within a matrix revision; no separate lane-revision entity exists.
- The draw engine emits lanes and groups together in a single matrix revision; the revision's fairness summary may include the lane uniformity metric, but nothing downstream (score placeholders, calculations, publication) consumes lane data for scoring.
- A move-pilot operation leaves the existing matrix revision untouched and creates no new matrix revision; the `Moved` assignment record stores a lane value (the mechanism for setting it — director picker vs. auto-assignment — is the follow-up item above).
- A retirement/drop-out does not create a matrix revision; only an explicit re-draw does.
- `flight_group` carries exactly one `matrixRevisionId`; lane values are read from assignments inside that revision, not from a separate object or derivation.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§3.3 lane penalty, §7.1 lane uniformity)
- `plan/architecture-requirements/data/matrix-and-assignments.md` (matrix revision content, assignment history, invariants)
- `plan/business-requirements/flight-group-management/move-pilot.md` (move retains matrix revision; does not rewrite history)
- `research/gliderscore-draw/README.md` (§1 — GliderScore assigns lanes after groups, used only as contrast; note the ticket originally cited `research/glidercore-draw/README.md`, a path typo)
