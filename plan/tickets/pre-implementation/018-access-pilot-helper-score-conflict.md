# Ticket 018 — Access: Pilot Self-Scoring vs. Helper Scoring Conflict

- **Category:** Access / Permissions
- **Priority:** Medium
- **Status:** ready
- **Depends on:** ticket 017 (helper role capabilities), ticket 013 (score edit conflict), ticket 012 (score status enum).
- **Decision:** Score submission follows first-accepted atomicity—once a valid score is accepted by the server (whether submitted by the pilot or their team helper), the score state transitions to `Submitted` and becomes read-only for both the pilot and helper; neither actor can overwrite an accepted score in place, and any further corrections require submitting a formal `Score Review Request` (or an explicit director edit); concurrent submissions are serialized by the server such that the first accepted submission establishes the submitted value, and any subsequent differing submission is rejected with an actionable message prompting a review request.

## Context

Both a pilot and their team helper have access to enter the pilot's flight scores. If a pilot and helper submit scores for the same flight at the same time or sequentially, the precedence, lock state, and conflict handling must be deterministic.

## Questions

1. **~~If a pilot self-submits and a helper later edits the same score, which takes precedence?~~** — **Resolved: First-accepted submission wins and locks to read-only (Decision 1).** Whichever valid submission is accepted first by the server sets the `Submitted` score. Neither pilot nor helper can overwrite an accepted submission in place.
2. **~~Is there a "pilot confirmed" state that locks the score from helper edits?~~** — **Resolved: `Submitted` state is universally read-only for participants (Decision 1).** Once a score moves from `NotEntered` / `Draft` to `Submitted`, the UI for both pilot and helper transitions to read-only `View` mode.
3. **~~Can a helper override a pilot-confirmed score, or is it read-only after confirmation?~~** — **Resolved: Read-only (Decision 1).** A helper cannot override an accepted score.
4. **~~How is the conflict surfaced — does the helper see that the pilot has already confirmed, and is a different flow required to change it?~~** — **Resolved: Status displayed in UI + Score Review workflow (Decision 2).** If one party views the flight after submission, the UI displays `Submitted (by Pilot)` or `Submitted (by Helper)` with timestamp. If a dispute or correction is required, the `Request Review` button initiates a formal Score Review Request.

## Decisions Needed

- (All resolved — see Decisions.)

## Decisions

- **First-Accepted Read-Only Rule (Decision 1):** When a score is accepted from either the pilot or authorized helper, the server commits the raw score components and transitions the outcome state to `Submitted`. The score entry form immediately switches to read-only view mode for all participant links (pilot and helper). Direct in-place editing is disabled. (2026-09-21)
- **Review Request Flow for Subsequent Edits (Decision 2):** Any correction to an already-submitted score must be submitted as a `Score Review Request` (if enabled in contest configuration). The review request records the proposed score adjustments and explanation, which is routed to the Contest Director for approval, rejection, or override. (2026-09-21)
- **Concurrent In-Flight Submissions (Decision 3):** If both pilot and helper have the entry form open and submit conflicting values concurrently, the server evaluates them in arrival order:
  - The first valid submission is accepted and committed as `Submitted`.
  - The second submission is rejected by the server with a structured `score_already_submitted` response, and the client form updates to display the currently submitted score along with the option to `Request Review`. (2026-09-21)

## Acceptance Criteria

- [ ] When a pilot submits a score, the corresponding helper's UI immediately reflects the `Submitted` status and disables direct editing.
- [ ] When a helper submits a score, the corresponding pilot's UI immediately reflects the `Submitted` status and disables direct editing.
- [ ] The API rejects direct score submission mutations targeting a flight assignment that is already in `Submitted`, `Official`, or `Locked` state.
- [ ] In the event of near-simultaneous submissions, the first accepted submission is preserved, and the second receives a rejection code instructing the user to submit a Score Review Request if changes are needed.
- [ ] Both pilot and helper retain the ability to submit a `Score Review Request` for a submitted score if score reviews are enabled for the contest.

## Sources

- `plan/architecture-requirements/participant-score-entry.md`
- `plan/architecture-requirements/score-review-and-validity-state.md`
- `plan/business-requirements/score-review-requests.md`
- `plan/ui/participant-scoring/participant-scoring.md`
- `plan/tickets/pre-implementation/013-sync-score-edit-conflict.md`
- `plan/tickets/pre-implementation/017-access-helper-role-capabilities.md`
