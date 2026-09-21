# Ticket 018 — Access: Pilot Self-Scoring vs. Helper Scoring Conflict

- **Category:** Access / Permissions
- **Priority:** Medium
- **Status:** Open

## Context

If a pilot self-submits a score and a helper also enters a score for the same pilot, the precedence is undefined.

## Questions

1. If a pilot self-submits and a helper later edits the same score, which takes precedence?
2. Is there a "pilot confirmed" state that locks the score from helper edits?
3. Can a helper override a pilot-confirmed score, or is it read-only after confirmation?
4. How is the conflict surfaced — does the helper see that the pilot has already confirmed, and is a different flow required to change it?

## Decisions Needed

- Precedence rules between pilot and helper score entries.
- Whether pilot confirmation locks the score.

## Sources

- `plan/business-requirements/managing-system.md`
- `plan/ui/participant-scoring/`
