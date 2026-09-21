# Ticket 031 — UI: Score Review Workflow (Pilot View)

- **Category:** UI / UX
- **Priority:** High
- **Status:** Open

## Context

The plan mentions "participant score-review requests enabled or disabled." When enabled, the pilot's experience is not specified.

## Questions

1. When score-review requests are enabled, what does the pilot see — their raw score components (time, landing, height penalty), or just the final group score?
2. Can the pilot flag a score as disputed, or only confirm it?
3. What is the dispute workflow — does the pilot submit a comment, or is it a simple "disputed" flag that notifies the director?
4. How long is the review window — can the pilot review after the round is marked complete, or only before?
5. What does the pilot see if a helper has already entered a score — is it pre-filled, or does the pilot enter from scratch?
6. Can the pilot edit their own score, or only confirm/dispute what the helper entered?

## Decisions Needed

- The pilot's score-review UX (what's shown, what actions are available).
- The dispute workflow and its effect on the score state.

## Sources

- `plan/ui/participant-scoring/`
- `plan/business-requirements/managing-system.md`
