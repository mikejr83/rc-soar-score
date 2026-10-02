# Ticket 009 — F5J Non-Droppable Zero: All-Zeros Edge Case

- **Category:** Scoring Engine
- **Priority:** Low
- **Status:** ready

## Context

The F5J "Non-Droppable 0" option prevents a motor-restart zero from being the dropped round. The spec says "the next lowest score which was not earned by a motor restart is selected." The behavior when all scores are motor-restart zeros is undefined.

The normalization side of this edge case is already settled by ticket 008 and the F5J doc's "Zero Score Clarifications": when every pilot in a group has a zero raw score, the normalized group score is 0 with no division by zero. That is _not_ in scope here — this ticket is only about the **dropped-round selection** stage (pipeline step 7 in `discipline-scoring.md`).

## Questions

1. If a pilot's lowest score is a motor-restart zero and _all_ other scores are also motor-restart zeros, is the drop skipped entirely, or is one zero dropped anyway? — **Resolved: skipped entirely (Decision 1).**
2. If the drop is skipped, does the pilot keep all scores (including the motor-restart zeros)? — **Resolved: yes, all scores are retained (Decision 1).**
3. How is this edge case displayed — does the fairness report or score breakdown indicate a non-droppable zero was present? — **Resolved: no special display (Decision 2).**

## Decisions Needed

- Behavior when no non-motor-restart score exists to drop. — **Decided (Decision 1).**
- How the edge case is surfaced in the UI. — **Decided (Decision 2).**

## Decisions

- **Decision 1 (Q1, Q2): Skip the drop entirely — the pilot keeps all scores.** When the contest's drop count requires removing a round but every round that would otherwise be eligible for the drop is a motor-restart zero (i.e., no non-motor-restart score exists to select), the engine **does not drop any round**. All of the pilot's round scores — including every motor-restart zero — are retained in the contest total.
  - Rationale: literal reading of the F5J rule — the non-droppable 0 "cannot be the round which is selected to be dropped," and only the "next lowest score which was **not** earned by a motor restart is selected." When no such round exists there is nothing valid to select, so the drop is a no-op. This never drops a motor-restart zero, matching the intent of the option.
  - Consequence: in the all-motor-restart case the pilot effectively drops fewer (possibly zero) rounds than the configured drop count. This is an accepted, deterministic outcome; no fallback to dropping a motor-restart zero is performed.
  - Distinction from ticket 008: this is a **per-pilot** dropped-round decision (pipeline step 7), not the group normalization (step 4). The two are independent; a group can be all-zeros for normalization _and_ a pilot can have an all-motor-restart score set for drop purposes.

- **Decision 2 (Q3): No special display.** When the drop is skipped in this edge case, it is **not** surfaced with any dedicated marker, note, or banner. Each retained motor-restart zero is displayed exactly as any other motor-restart zero. The calculation metadata already records that a non-droppable zero was present and that no round was dropped (per `discipline-scoring.md` rule 25/6 — the dropped-round decision must be reproducible), so the information is available in the stored calculation metadata for auditing, but the UI makes no distinction and shows no indication that a drop was skipped. This is a presentation-only decision; it does not change stored values.

## Acceptance criteria

- Under F5J "Non-Droppable 0," when a pilot's lowest round is a motor-restart zero and there is **no** non-motor-restart round available to drop, the engine **skips the drop** and the pilot retains **all** of their round scores (including every motor-restart zero) in the contest total. No motor-restart zero is ever dropped.
- In the same situation, the pilot effectively drops fewer (possibly zero) rounds than the configured drop count; this is the expected deterministic outcome.
- The dropped-round decision (including the "no round dropped" case) is recorded in the calculation metadata so the contest total and drop decision can be reproduced from the immutable raw data.
- The UI shows **no** special indication that a drop was skipped: retained motor-restart zeros render identically to any other motor-restart zero (no dedicated marker, note, or results-page banner).
- Golden calculation fixtures include: (a) a pilot with all motor-restart zeros and a configured drop count > 0 (drop skipped, all retained); (b) a pilot with at least one non-motor-restart score where the lowest is a motor-restart zero (the next-lowest non-motor-restart round is dropped). The service and any offline calculation library pass the same fixtures.
- This behavior is independent of group normalization: an all-zero group still normalizes to 0 with no division by zero (ticket 008 / `discipline-scoring.md` rule 5).

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Motor Restart)
- `plan/architecture-requirements/discipline-scoring.md` (F5J scoring rule 4)
