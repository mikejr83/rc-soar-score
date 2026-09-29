# Ticket 034 — Business: Re-Flight Decline Limits

- **Category:** Business Rules
- **Priority:** Medium
- **Status:** Open

## Context

Re-flight priority 2 allows a randomly selected competitor to decline. The F5J spec says "the draw is repeated until the group is filled" and "if a group cannot be filled, the priority moves to the next." The maximum number of declines before giving up is not defined.

## Questions

1. What is the maximum number of declines before the re-flight group is abandoned?
2. If all remaining pilots decline, is the re-flight cancelled, or is the original score kept?
3. Can the same pilot be selected multiple times in the random draw if they decline?
4. Is there a time limit for a pilot to accept or decline a re-flight offer?
5. How does the decline history affect subsequent re-flights (e.g., is a pilot who declined once excluded from future draws)?

## Decisions Needed

- The decline limit and its effect on the re-flight process.
- How declines are tracked and displayed.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Re-Flights, priority 2)
- `plan/business-requirements/disciplines/f3j.md` (Re-Flights)
