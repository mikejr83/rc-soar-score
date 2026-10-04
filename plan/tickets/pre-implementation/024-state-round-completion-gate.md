# Ticket 024 — State Machine: Round Completion Gate

- **Category:** Contest State Machine
- **Priority:** Medium
- **Status:** Decided
- **Decision:** Round completeness is derived; the director locks and unlocks rounds; late edits need a recorded override and trigger recalculation. (2026-10-04)

## Context

What prevents a round from being marked complete while scores are still being entered is not defined.

## Questions

1. ~~Is there a "round complete" confirmation gate that the director must trigger, or is it automatic?~~ **Resolved:** completeness is derived, not stored. A round is complete when every current assignment credited to it has an official score (including official zero and retired outcomes) and no review request is open ([round.md](../../data-model/entities/round.md)). Separately, the director can lock a round (`Open` to `Locked`) and unlock it, and each change is audited.
2. ~~Can a round be marked complete if some scores are still in "pending review" state?~~ **Resolved: no.** An open review request keeps the round incomplete.
3. ~~Can scores be entered or edited after a round is marked complete?~~ **Resolved:** while a round is `Open`, yes. While `Locked`, score entry and assignment moves are rejected unless the director overrides with a recorded reason.
4. ~~If a score is edited after a round is complete, does it trigger a recalculation and a new calculation revision?~~ **Resolved:** an edit is an official-score revision, and derived results are recomputed and stamped with the revisions used (ticket 010).
5. ~~What prevents a director from marking a round complete by mistake?~~ **Resolved for the data model:** completeness cannot be set by mistake because it is derived. Locking is reversible. Whether the UI asks for confirmation before locking is a UI decision for the contest administration screens.

## Decisions

- Round completeness is derived. The director controls locking. Late edits need an override with a reason and trigger recalculation.
- No schema impact.

## Sources

- `plan/architecture-requirements/data/contest.md`
- `plan/ui/contest-administration/`
