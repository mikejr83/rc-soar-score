# Ticket 007 — F3J Fixed Late-Landing Penalty

- **Category:** Scoring Engine
- **Priority:** Medium
- **Status:** Open

## Context

`discipline-scoring.md` references a "fixed late-landing penalty" for F3J in its test requirements, but the F3J business doc only states that "a late landing does not receive the landing bonus." No fixed penalty amount is given.

## Questions

1. What is the fixed late-landing penalty value for F3J?
2. Is it configurable per contest, or a fixed constant in the rules?
3. How does it combine with the removal of the landing bonus — is it a subtraction from the base points, or a separate penalty component?
4. Does the late-landing penalty interact with the working-time cap (i.e., is the penalty applied even if the time is capped at the working time)?

## Decisions Needed

- The exact penalty value and its configuration model.
- Where it sits in the calculation pipeline.

## Sources

- `plan/architecture-requirements/discipline-scoring.md` (test requirements, F3J)
- `plan/business-requirements/disciplines/f3j.md`
