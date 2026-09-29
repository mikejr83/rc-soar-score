# Ticket 024 — State Machine: Round Completion Gate

- **Category:** Contest State Machine
- **Priority:** Medium
- **Status:** Open

## Context

What prevents a round from being marked complete while scores are still being entered is not defined.

## Questions

1. Is there a "round complete" confirmation gate that the director must trigger, or is it automatic when all groups have scores?
2. Can a round be marked complete if some scores are still in "pending review" state?
3. Can scores be entered or edited after a round is marked complete?
4. If a score is edited after a round is complete, does it trigger a recalculation and a new calculation revision?
5. What prevents a director from marking a round complete by mistake — is there a confirmation dialog?

## Decisions Needed

- The round-completion trigger (manual vs. automatic).
- Whether scores are editable after round completion.

## Sources

- `plan/architecture-requirements/data/contest.md`
- `plan/ui/contest-administration/`
