# Ticket 037 — Business: F5J "No Altitude Recorded" — Purpose and Drop Behavior

- **Category:** Business Rules
- **Priority:** Low
- **Status:** Open

## Context

The F5J "No Altitude Recorded" option produces a zero score but is tracked separately from a regular zero. Its purpose and interaction with the drop logic are not specified.

## Questions

1. What is the purpose of the "No Altitude Recorded" categorization — for post-contest analysis, protest handling, or something else?
2. Is a "No Altitude Recorded" zero droppable or non-droppable in the drop logic?
3. Does it interact with the "Non-Droppable 0" motor-restart option (i.e., is it treated as a motor-restart zero for drop purposes)?
4. How is it displayed on the public site — as "0" or "No Altitude Recorded"?
5. Can a pilot who selected "No Altitude Recorded" later have their altitude recorded and their score corrected?

## Decisions Needed

- The purpose of the "No Altitude Recorded" category.
- Its behavior in the drop logic and display.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (No Altitude Recorded)
- `plan/architecture-requirements/discipline-scoring.md` (F5J scoring rule 4)
