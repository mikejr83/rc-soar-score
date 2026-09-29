# Ticket 003 — Matrix Revision Granularity

- **Category:** Data Model / Schema
- **Priority:** High
- **Status:** ready
- **Depends on:** ticket 021 (mid-contest re-draw) — *conditional.* The granularity model here assumes a re-draw only (re)generates **future** rounds and leaves past rounds in their original revision; if 021 decides past rounds are re-optimized, "the current matrix = union of all revisions" still holds but the round→revision ownership for redrawn past rounds must be revisited. (021 is the ticket that depends on this model.)
- **Decision:** Revisions are immutable full snapshots, one per draw/re-draw. Each revision stores only the rounds it generated; every round belongs to exactly one revision, and each group's `matrixRevisionId` points to the revision that drew that round. A pilot move or re-flight creates a new assignment record — never a new revision and never an amendment. A re-draw produces a new revision covering the (re)generated rounds; "the current matrix" is the union of all revisions.

## Context

A matrix revision is described as immutable. But when a pilot moves mid-round, the draw's *effective* membership changes. The revision itself is untouched (per ticket 002, a move and a drop-out create no new matrix revision); the change lives in new assignment records of type `Moved` or `Reflight`. The open questions are how the "governing revision" is referenced, how multiple revisions can coexist across a contest, and what happens to superseded revisions.

## Questions

1. When a pilot is moved mid-round, is a new matrix revision created, or is the existing revision amended? — **Resolved: neither. The revision is immutable; the move is a new assignment record. See Decisions.**
2. How does the revision counter and the `matrix` relation on `flight_group` handle a move — does each flight group point to the revision that governed it at the time of the flight? — **Resolved (see Decisions).**
3. Can a contest have multiple matrix revisions simultaneously active (e.g., one for rounds 1–3, a new one for rounds 4+ after a re-draw)? — **Resolved: yes, each revision owns the rounds it generated (see Decisions).**
4. What is the retention policy for superseded matrix revisions? — **Resolved: keep all, forever (see Decisions).**

## Decisions Needed

- Revision model (immutable full snapshots vs. amendment log).
- How `flight_group` links to the matrix revision that produced it.
- Whether multiple revisions can be active simultaneously, and for what round ranges.
- Retention policy for superseded revisions.

## Decisions

- **Revision model (Q1):** A matrix revision is an **immutable full snapshot** of its rounds, groups, and assignments. There is **no amendment log** and no in-place mutation of a revision. A pilot move and a re-flight do **not** create a new matrix revision and do **not** amend an existing one; they create new assignment records of type `Moved` or `Reflight` that carry `sourceAssignment`, `actor`, `reason`, `timestamps`, and the revision/contest context for the move (consistent with `data/matrix-and-assignments.md` and `move-pilot.md`).
- **Governing revision & `flight_group.matrixRevisionId` (Q2/Q3):** A group's round belongs to exactly one matrix revision, and `flight_group.matrixRevisionId` is set once — at group creation — to **the revision that drew that group's round**. It is never re-pointed by a move or re-flight. A `Moved`/`Reflight` record points *to* the group (and the revision it references), not the other way around. The group's **live composition** is derived at read time: for each pilot, the revision's `Original` assignment is overlaid by the latest accepted `Moved`/`Reflight` record for that pilot (the superseded source record is retained in history, never deleted). The revision counter (`revisionNumber`) is unaffected by moves and only increments on a new draw/re-draw.
- **Revision round ownership (Q3):** Each revision is a full snapshot, but it stores **only the rounds it generated** (e.g., the initial full draw, or the (re)generated future rounds after a re-draw). Every round belongs to exactly one revision. "The current/whole-contest matrix" is therefore the **union of all revisions** — past, already-flown rounds resolve to the revision that drew them, future rounds resolve to the latest revision. A re-draw produces a new revision for the rounds it (re)generated; it does not re-store already-flown rounds. (Whether a re-draw ever re-optimizes *past* rounds is owned by ticket 021.)
- **Scores reference the revision that produced the group** (the revision in `matrixRevisionId`), and the assignment record that actually produced the scored flight — so a score can always be traced to (revision, assignment chain). This matches `move-pilot.md`'s "retain … the contest/matrix revision for the move."
- **Retention (Q4):** All matrix revisions are **retained forever within the contest** as immutable history. There is no automatic cleanup, no retention window, and no director "purge" action for revisions. The only path that removes revision data is **contest deletion** (governed by the deletion-state flow in `data/contest.md`), which is delisted/handled per that flow and never physically deleted by ordinary sync. Revisions must stay queryable for audit, fairness reports, and tracing any score/move back to its draw.

## Acceptance criteria

- The data model stores a matrix revision as an immutable snapshot: rounds, groups, `Original` assignments, seed, fairness summary, and metadata. There is no mutation path that edits an existing revision's contents.
- A pilot move or re-flight creates a new assignment record (`Moved`/`Reflight`) and changes no matrix revision; `revisionNumber` is not incremented.
- `flight_group.matrixRevisionId` is set once, at group creation, to the revision that drew the group's round, and is never re-pointed by a move or re-flight.
- The application derives a group's current membership by overlaying the current `Moved`/`Reflight` records onto the revision's `Original` assignments; superseded source assignments remain queryable in the audit history.
- Each revision stores only the rounds it generated; every round resolves to exactly one revision, and "the current matrix" is the union of all revisions.
- A score references (a) the revision that drew the group's round via the group's `matrixRevisionId` and (b) the specific assignment record that produced the scored flight.
- Superseded revisions are retained forever within the contest; the only path that removes them is contest deletion. There is no automatic cleanup, retention window, or revision-purge action.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§7.2 Matrix Revision Entity Contract)
- `plan/architecture-requirements/data/contest.md` (deletion-state flow; config revision mutability rules)
- `plan/architecture-requirements/data/matrix-and-assignments.md` ("a new draw never overwrites an earlier revision"; assignment history; invariants)
- `plan/business-requirements/flight-group-management/move-pilot.md` (move retains prior assignment, actor, reason, time, and contest/matrix revision)
- `plan/tickets/pre-implementation/002-data-lane-assignment-revision.md` (lanes embedded in the revision; move/drop-out create no new revision; one `matrixRevisionId` per group)
- `plan/tickets/pre-implementation/021-state-mid-contest-redraw.md` (open: whether a re-draw re-optimizes past rounds; state during a re-draw)
