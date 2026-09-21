# Ticket 023 — State Machine: Is "Contest Ended" Reversible?

- **Category:** Contest State Machine
- **Priority:** Low
- **Status:** Open

## Context

If a contest is marked ended, it is unclear whether it can be re-opened (e.g., for a protest that changes final standings).

## Questions

1. Can a contest that has been marked ended be re-opened?
2. If re-opened, can scores be edited, or are they locked?
3. Is there a "contest ended but scores still editable" intermediate state?
4. Does re-opening a contest create a new calculation revision?
5. How does the public site display a re-opened contest — does it show "ended" or "in progress"?

## Decisions Needed

- Whether the ended state is reversible.
- The state transitions around contest end/re-open.

## Sources

- `plan/architecture-requirements/data/contest.md`
