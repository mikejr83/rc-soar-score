# Ticket 035 — Business: Re-Flight "Better Of" Scoring

- **Category:** Business Rules
- **Priority:** Medium
- **Status:** Decided (see [#80](https://github.com/mikejr83/rc-soar-score/issues/80))

## Context

The F5J spec states that for re-flight groups, "the better of their score in the ongoing round and the re-flight score will become their round score" — for all competitors, not just the originally re-flown pilot. This seems unusual.

## Questions

1. Is "better of" scoring confirmed for all pilots in the re-flight group, or only the originally re-flown pilot?
2. If a pilot flew well in the original round (e.g., 900) and the re-flight group is weaker (best score 700), does the pilot keep their 900?
3. How does "better of" interact with the drop logic — is the better score used for the drop, or are both scores considered?
4. How is the "better of" decision displayed — does the score breakdown show both the original and re-flight scores?
5. Does the same "better of" rule apply to F3J re-flights?

## Decisions Needed

- Confirmation of the "better of" rule scope.
- How it interacts with the drop logic and display.

## Sources

- `plan/business-requirements/disciplines/f5j.md` (Re-Flights)
- `plan/business-requirements/disciplines/f3j.md` (Re-Flights)
