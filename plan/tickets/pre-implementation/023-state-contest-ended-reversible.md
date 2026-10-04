# Ticket 023 — State Machine: Is "Contest Ended" Reversible?

- **Category:** Contest State Machine
- **Priority:** Low
- **Status:** Decided
- **Decision:** Completed is not reversible in the first release; corrections use the audited score correction workflow. (2026-10-04)

## Context

If a contest is marked ended, it is unclear whether it can be re-opened (e.g., for a protest that changes final standings).

## Questions

1. ~~Can a contest that has been marked ended be re-opened?~~ **Resolved: not in the first release.** There is no ordinary transition back from `Completed`. If reopening is ever required, it must be added as an explicit, authorized transition rather than inferred from an edit ([contest-state-and-transitions.md](../../architecture-requirements/contest-state-and-transitions.md)).
2. ~~If re-opened, can scores be edited, or are they locked?~~ **Resolved:** a completed contest takes authorized score corrections, which preserve prior values and audit history. Participant scoring is closed, and no new rounds, participation or matrix changes are allowed.
3. ~~Is there a "contest ended but scores still editable" intermediate state?~~ **Resolved: no separate state.** The contest stays `Completed` and corrections go through the score correction and audit workflow.
4. ~~Does re-opening a contest create a new calculation revision?~~ **Resolved:** a correction is a new official-score revision. Derived results are recomputed from raw data and stamped with the revisions they were computed under (ticket 010; [offline-synchronization.md](../../architecture-requirements/offline-synchronization.md), Scores and Recalculation).
5. ~~How does the public site display a re-opened contest?~~ **Not applicable.** The contest remains `Completed`. A corrected result is republished under the contest's public update mode.

## Decisions

- `Completed` is not reversible in the first release; corrections use the audited score correction workflow.
- No schema impact.

## Sources

- `plan/architecture-requirements/data/contest.md`
