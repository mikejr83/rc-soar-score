# Ticket 028 — Matrix: Back-to-Back Constraint

- **Category:** Matrix / Draw
- **Priority:** Low
- **Status:** Open

## Context

GliderScore supports a "back-to-back" constraint that prevents a pilot from flying in the last group of round N and the first group of round N+1. The plan does not mention it.

## Questions

1. Should the back-to-back constraint be added?
2. If yes, is it a hard constraint or a soft optimization goal?
3. Is it configurable per contest (director can enable/disable)?
4. How does it interact with re-flights — can a re-flight group violate the back-to-back constraint?

## Decisions Needed

- Whether to add the back-to-back constraint.
- Its constraint class (hard vs. soft) and configuration model.

## Sources

- `research/glidercore-draw/README.md` (§1, §6 question 5)
