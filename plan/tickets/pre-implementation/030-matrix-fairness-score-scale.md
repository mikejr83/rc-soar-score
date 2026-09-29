# Ticket 030 — Matrix: Fairness Score 0–100% Scale Anchor

- **Category:** Matrix / Draw
- **Priority:** Low
- **Status:** Open

## Context

The fairness score is a normalized value from 0% to 100% comparing achieved J against the theoretical lower bound J_ideal. The second anchor (what 0% represents) is not defined.

## Questions

1. What does 0% on the fairness scale represent — the worst observed, the theoretical worst, or a fixed constant?
2. Is the 100% anchor (J_ideal) computable for all contest sizes, or is it an approximation?
3. How is the fairness score computed — is it `1 - (J - J_ideal) / (J_worst - J_ideal)`, or a different formula?
4. Should the fairness score be reported per round or for the entire matrix?

## Decisions Needed

- The formula for the 0–100% fairness score.
- The definition of J_worst (the 0% anchor).

## Sources

- `plan/architecture-requirements/matrix-draw.md` (§7.1, Overall Fairness Score)
- `research/glidercore-draw/README.md` (§6 question 7)
