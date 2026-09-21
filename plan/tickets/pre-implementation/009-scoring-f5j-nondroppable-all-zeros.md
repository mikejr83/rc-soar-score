# Ticket 009 — F5J Non-Droppable Zero: All-Zeros Edge Case

- **Category:** Scoring Engine
- **Priority:** Low
- **Status:** Open

## Context

The F5J "Non-Droppable 0" option prevents a motor-restart zero from being the dropped round. The spec says "the next lowest score which was not earned by a motor restart is selected." The behavior when all scores are motor-restart zeros is undefined.

## Questions

1. If a pilot's lowest score is a motor-restart zero and *all* other scores are also motor-restart zeros, is the drop skipped entirely, or is one zero dropped anyway?
2. If the drop is skipped, does the pilot keep all scores (including the motor-restart zeros)?
3. How is this edge case displayed — does the fairness report or score breakdown indicate a non-droppable zero was present?

## Decisions Needed

- Behavior when no non-motor-restart score exists to drop.
- How the edge case is surfaced in the UI.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Motor Restart)
- `plan/architecture-requirements/discipline-scoring.md` (F5J scoring rule 4)
