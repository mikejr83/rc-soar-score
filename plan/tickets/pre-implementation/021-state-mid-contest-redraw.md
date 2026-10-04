# Ticket 021 — State Machine: Mid-Contest Draw Regeneration

- **Category:** Contest State Machine
- **Priority:** High
- **Status:** Ready
- **Decision:** A mid-contest re-draw is an explicit, atomic director action. Retirement is not a re-draw trigger (the retired pilot stays in the matrix and is scored zero for unflown rounds). The director may redraw any subset of rounds — including already-flown rounds — but the UI defaults to and steers toward future-only redraws and shows a high-importance warning before redrawing scored rounds; confirmed redraws of scored rounds remove those scores and reset the rounds to not-flown. The draw engine optimizes against the pairwise meeting history of kept (non-redrawn) rounds only. No new contest state is introduced, round numbers are preserved, and each round still belongs to exactly one matrix revision (per ticket 003).

## Decisions

1. **A retirement does NOT trigger a re-draw (Q1).** Retiring is a status overlay on the participation link (per `data/README.md`: `status = Retired`, `retired_at_round = N`) that (a) makes the scoring engine score all unflown rounds from N onward as zero with a `Retired` status, and (b) tells the system not to wait on that pilot's scores. The retired pilot **still appears in the matrix as if participating** — no new matrix revision is created, no rounds are re-drawn, and the matchup history / groupings are unchanged.

2. **Scope of a mid-contest re-draw (Q2 / former Q2):** The director **may redraw any set of rounds — including already-flown rounds** — but this is an extreme, rare operation. The UI defaults to, and steers the director toward, **redrawing future (unscored) rounds only**. If the director chooses to include already-flown rounds, a **high-importance warning** must state that scores for those rounds have already been recorded and will be invalidated and removed. On confirmation, scores on any redrawn round are **removed**, and any such round is **treated as not flown** after the re-draw.

   Consequences:
   - A re-draw of already-flown rounds **does invalidate existing scores** — this supersedes `contest-state-and-transitions.md`'s `Running` rule that "participation … [are] fixed," for this explicit, warned action.
   - The invalidated scores follow the same removal/audit path as any other invalidation; they must not be silently dropped. The round is then scored fresh (or left unscored) as with any other re-drawn round.
   - A re-draw of only future rounds has no effect on existing scores and is the normal case.

3. **Matchup history for a partial re-draw (former Q4):** When a re-draw covers some rounds, the draw engine seeds its optimization with pairwise meeting counts from **only the rounds that are kept (not re-drawn)**. Old pairings from rounds being discarded are **excluded** from the history, since they will no longer count. This is consistent with `matrix-draw.md` §3.1 (c(p_i, p_j) counts meetings across all evaluated rounds) — a re-drawn round's old assignments are not "evaluated" after the re-draw.

4. **Contest state during a re-draw (former Q5):** **No new state is introduced.** The re-draw is a synchronous, atomic API call. The contest's execution lifecycle (`Ready`/`Running`), scoring access, admin lock, publication, and visibility are all unchanged by the operation itself. Concurrency is guarded by the same normal revision check the system already uses for every mutation (a stale or unauthorized mutation is rejected without changing the contest — see `contest-state-and-transitions.md` §Transition invariants). There is no transient "re-drawing" substate and no new lock.

5. **Round numbers across a re-draw (former Q3):** **Round numbers are preserved.** A re-drawn round keeps its round number; it is simply reset to "not flown" and given new groupings. A re-draw may cover any subset of rounds (including non-contiguous ones) — e.g. redo round 3 and 5 of a 10-round contest while keeping round 4 — and each round still belongs to exactly one revision (per ticket 003). There is no renumbering, no appending at the end, and no contiguity requirement.

## Context

A mid-contest re-draw regenerates part of the flight matrix after the contest has started. A pilot **retiring** is explicitly _not_ a trigger for this — the retired pilot remains in the matrix and is scored zero for unflown rounds (see Decisions). The re-draw is initiated by the director; the spec did not previously define how it interacts with existing matrix revisions, scores, and the draw engine.

## Questions

1. ~~When a pilot drops out, is the draw regenerated only for future rounds, or must the entire matrix be re-optimized?~~ — **Resolved: retirement is not a re-draw trigger; the pilot stays in the matrix (Decision 1).**
2. **What can a director redraw mid-contest, and what happens to scored rounds?** — **Resolved: any subset of rounds may be redrawn; the UI steers to future-only; redrawing a scored round is warned about and, on confirmation, removes its scores and resets the round to not-flown (Decision 2).**
3. ~~Can a new matrix revision cover only rounds N+1 onward?~~ — **Resolved: yes; a re-draw produces a new revision covering exactly the rounds it (re)generated (Decision 5, per ticket 003).**
4. ~~How does the draw engine's history account for discarded rounds?~~ — **Resolved: only kept (non-redrawn) rounds seed the pairwise meeting history (Decision 3).**
5. ~~What is the contest state during the re-draw?~~ — **Resolved: no new state; the re-draw is a synchronous atomic call guarded by the normal revision check (Decision 4).**

## Decisions Needed

- (All resolved — see Decisions.)

## Acceptance criteria

- **Retirement:** Retiring a pilot (a) sets the participation overlay to `Retired` with `retired_at_round = N`, (b) scores all unflown rounds from N onward as zero with a `Retired` status, and (c) does not create a matrix revision, does not redraw any round, and leaves the retired pilot visible in the matrix.
- **Re-draw scope:** The re-draw API accepts a set of target round numbers and a `baseRevision`. It may include any subset of rounds (future, past, or non-contiguous). Each re-drawn round keeps its round number and is reset to not-flown with new groupings.
- **Score invalidation:** If a re-drawn round has existing scores, the UI presents a high-importance warning stating that recorded scores will be invalidated and removed. On confirmation, those scores are removed through the standard score-removal/audit path (retained in audit history, not silently dropped), and the round is treated as not flown. Redrawing only unscored rounds has no effect on existing scores.
- **Draw engine history:** The optimization's pairwise meeting counts include only kept (non-redrawn) rounds; old pairings of discarded rounds are excluded.
- **State & concurrency:** No new contest lifecycle state, transient substate, or lock is introduced. The re-draw is atomic; it is rejected without side effects if the contest revision no longer matches the supplied `baseRevision`.
- **Revision model (with ticket 003):** The re-draw emits exactly one new matrix revision storing only the rounds it (re)generated; every round belongs to exactly one revision; superseded revisions are retained. `revisionNumber` increments by one.
- **UI:** The default re-draw selection is future unscored rounds only; selecting scored rounds requires acknowledging the high-importance warning.

## Sources

- `plan/architecture-requirements/matrix-draw.md` (incremental round generation)
- `plan/architecture-requirements/data/contest.md`
