# Ticket 031 — UI: Score Review Workflow (Pilot View)

- **Category:** UI / UX
- **Priority:** High
- **Status:** ready
- **Decision:** The pilot-facing review workflow: the `Request Review` window is state-driven (score `Submitted`, reviews enabled, not locked at any scope, no other pending request); submitted requests are immutable for the participant (no withdrawal); after resolution the pilot sees current official values plus an outcome status line (no rejection reason, no diff); applying a lock requires the director to resolve or dismiss every outstanding request in scope (none may remain pending); the score detail view always shows the current official components, with the pilot's original entry preserved in the audit trail (director views only).

## Context

The plan mentions "participant score-review requests enabled or disabled." When enabled, the pilot's experience is not specified. This ticket resolves the pilot-facing review UX. It builds on already-settled behavior in tickets 012, 017, and 018 and in `plan/business-requirements/score-review-requests.md` and `plan/ui/participant-scoring/participant-scoring.md`.

## Questions

1. ~~When score-review requests are enabled, what does the pilot see — their raw score components or just the final group score?~~ — **Resolved: see the submitted raw components plus preliminary group results (Decision 5).**
2. ~~Can the pilot flag a score as disputed, or only confirm it?~~ — **Resolved: no standalone "disputed" flag; the only correction path is a Review Request with an optional explanation (Decision 6).**
3. ~~What is the dispute workflow — comment, or simple flag notifying the director?~~ — **Resolved: editable form prepopulated with submitted values, optional explanation, director notified (Decision 6; settled by `score-review-requests.md`).**
4. How long is the review window — can the pilot review after the round is marked complete, or only before? — **Resolved: state-driven window, see Decision 1.**
5. ~~What does the pilot see if a helper has already entered a score — pre-filled, or enter from scratch?~~ — **Resolved: helper-entered score is displayed read-only; any correction goes through the same Review Request flow (Decisions 5, 7).**
6. ~~Can the pilot edit their own score, or only confirm/dispute what the helper entered?~~ — **Resolved: no in-place edits ever; correction is always via Review Request (Decision 7).**

## Decisions

- **Decision 1 (Q4): The review window is state-driven.** `Request Review` is shown exactly when the score is in the `Submitted` state, review requests are enabled in the contest configuration, and no lock applies at score, group, round, or contest level, and no other review request for that flight assignment is pending. The window closes when the director marks the score `Official` or applies a lock at any scope — whichever happens first. Round completion by itself has no effect; the director's official/lock action is what closes the window. (This keeps the ticket implementable without ticket 024's round-completion gate.)
- **Decision 2: No pilot withdrawal for the initial release.** Once the pilot submits a review request, the request is immutable for the participant: there is no withdraw/cancel action. Only the director can resolve it (`Approved` / `Rejected`) or supersede it via an administrative action (official edit or marking official while pending). A new review request can be submitted only after the current one reaches a terminal state and the score's window conditions in Decision 1 hold again.
- **Decision 3: Post-resolution pilot view is official values + outcome status only.** After the director resolves a review request, the participant read-only view shows the current official score components and a status line indicating the outcome ("Review approved" / "Review rejected"). It does **not** show the director's rejection reason and does **not** show a side-by-side of submitted vs. official values. The rejection reason (when recorded) remains available in the director/audit views only; the originally submitted values remain in the audit trail per `score-review-requests.md`.
- **Decision 4: Lock application forces resolution of outstanding review requests.** A lock may not be applied while leaving a request pending: when the director applies a lock at any scope (score, group, round, or contest), the application performs a check for outstanding score review requests in that scope. The director must then evaluate each outstanding request individually and resolve it — approve, reject, or dismiss (supersede, attributed to the lock action). A review request can never remain pending on a locked score. Superseded-by-lock requests remain in the audit trail with `Superseded` status and a pointer to the lock event. (Same treatment as the existing rule that an official edit or official mark-up while pending supersedes the request; here the director makes the supersedure explicit at lock time rather than the system doing it silently.)
- **Decision 5 (Q1, Q5): What the pilot sees — submitted raw components plus preliminary results.** The score detail view shows the discipline-specific raw score components (time, landing, height, etc., per the discipline profile) plus cumulative penalty, the submission time, and the score state (`Submitted`, `Under review`, `Official`, `Locked`). It does not show only the final group score. Beneath it, the view shows the preliminary group results table (pilot name, discipline values, raw score, round score, updated as participant submissions arrive, with pending-review indicators), and the pilot's current contest placement with up to three pilots above and below, with missing-score estimates labeled as estimates. These are the settled contents of `participant-scoring.md` and `contest-self-scoring.md`.
- **Decision 6 (Q2, Q3): No standalone "disputed" flag — the only correction path is a Review Request.** The pilot cannot flag a score as disputed in isolation and cannot confirm/acknowledge it in a way that changes state. Correction is only possible by `Request Review`, which opens the editable form prepopulated with the submitted values, adds an optional explanation field, and enables `Submit` only when at least one value changes. Submission records the request, notifies the director in the application (after sync or via the real-time connection), and the view switches to read-only showing the pending-review state with the modified fields highlighted. This is the process already specified in `score-review-requests.md` and `contest-self-scoring.md`.
- **Decision 7 (Q5, Q6): Helper-entered scores; pilot edit rights.** A score entered by a helper is visible to the pilot read-only, displayed with attribution (`Submitted (by Helper)`) and the submission timestamp (ticket 018, Decision 2). Neither the pilot nor the helper can edit an accepted score in place; a correction is always submitted as a Review Request, whose prepopulated form uses the currently submitted values regardless of who entered them (tickets 017/018, `contest-self-scoring.md`).
- **Decision 8: After a direct administrative correction, the detail view shows the current official components.** If the director enters or corrects a score administratively (no review request involved), the pilot's score detail view shows the current official raw components, not the pilot's original entry. The pilot's original submission is retained in the audit trail and remains visible in director views and the administrator review details; the participant view does not render a side-by-side or delta marker for administrative corrections.

## Decisions Needed

- (All resolved — see Decisions 1–8.)

## Acceptance criteria

- The participant score detail view renders discipline-specific raw components plus cumulative penalty, submission time, and score state; below them, the preliminary group results table and the pilot's current placement (±3 pilots, estimates labeled) are shown, with pending-review indicators where applicable. (Decision 5)
- No in-place edit is available for a submitted score, by either pilot or helper; the detail form is read-only. (Decisions 6, 7)
- `Request Review` is visible exactly when: review requests are enabled in contest configuration, the score is `Submitted`, not `Official`, no score/group/round/contest lock applies, and no other review request for the flight assignment is pending. It is hidden in all other cases. (Decision 1)
- The review request form is prepopulated with the currently submitted values; `Submit` is enabled only after at least one value changes; an optional explanation message can accompany the request. After submission the form is read-only, modified fields are highlighted, and the score shows a pending-review state. (Decision 6)
- A submitted review request cannot be withdrawn by the participant; its only exits are director approval, rejection, or supersession (administrative edit, official mark-up, or explicit lock-time resolution). A new request is possible only after the prior request is terminal and the Decision 1 window conditions hold again. (Decision 2)
- After the director resolves a review, the participant view shows the current official components plus an outcome status line ("Review approved" / "Review rejected") and nothing more — no rejection reason text and no submitted-vs-official diff. The rejection reason and originally submitted values remain in the director/audit views. (Decision 3)
- Applying a lock at any scope first checks for outstanding review requests in scope and requires the director to approve, reject, or dismiss each individually before the lock applies; a pending request never remains on a locked score; dismissed requests are recorded as `Superseded` with a pointer to the lock event. (Decision 4)
- A score entered by a helper is shown to the pilot read-only with `Submitted (by Helper)` attribution and timestamp; a pilot correction goes through the same Review Request flow with the form prepopulated from the helper-entered values. (Decision 7)
- After a direct administrative correction (no review request), the participant detail view shows the current official components, with the pilot's original entry visible only in audit/director views. (Decision 8)

## Sources

- `plan/ui/participant-scoring/participant-scoring.md`
- `plan/business-requirements/score-review-requests.md`
- `plan/business-requirements/contest-self-scoring.md`
- `plan/business-requirements/contest-official-scoring.md`
- `plan/architecture-requirements/score-review-and-validity-state.md`
- `plan/architecture-requirements/participant-score-review.md`
- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/tickets/pre-implementation/017-access-helper-role-capabilities.md`
- `plan/tickets/pre-implementation/018-access-pilot-helper-score-conflict.md`
- `plan/tickets/pre-implementation/013-sync-score-edit-conflict.md`
- Related open ticket: 024 (round completion gate) — Decision 1 deliberately does not depend on it.
