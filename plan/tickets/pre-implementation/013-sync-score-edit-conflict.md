# Ticket 013 — Offline Sync: Score Edit Conflict Resolution

- **Category:** Offline Sync
- **Priority:** High
- **Status:** ready
- **Decision:** Director's latest authorized decision wins; losing participant submission becomes a silent, non-blocking review record; superseded review requests require an explicit director approve/reject/supersede. No field merge, no helper-vs-helper, no stale-device handling in this ticket.

## Context

Under the one-active-administration-installation rule, all helper edits on the active device are attributed to the contest director, so there is no sanctioned helper-vs-helper conflict. The real offline sync conflict on a score is a director-made official edit (from the active installation) versus a concurrent participant submission that arrives at the server.

## Scope (decided)

- 013 covers only the **director official edit vs. concurrent participant submission** conflict.
- Stale/revoked-device (helper on a deactivated installation) conflicts are out of scope for this ticket.
- Field-level merge of concurrent official edits is not part of this design; a single latest authorized director decision is authoritative.

## Questions

1. ~~When two offline edits conflict on the same score...~~ Resolved: the conflict is director edit vs. participant submission, not two helper edits.
2. ~~Which fields are mergeable...~~ N/A — no field-level merge; the director's decision is atomic and authoritative.
3. ~~How is the conflict surfaced to the user...~~ Resolved: silent review record, no forced action (see Decisions).
4. ~~When the participant submission loses...~~ Resolved: stored as a silent review record, no participant notification, no auto review request, inert until the director opens a review.
5. ~~If a participant review request arrives while the director's offline edit is pending...~~ Resolved: held in a "requires decision" state; director must explicitly approve, reject, or supersede; no auto default.
6. ~~Does the same precedence apply on a simultaneous arrival?~~ Resolved: yes — precedence is by authority, not timestamp, so simultaneity does not change the outcome.

## Acceptance Criteria

- When a director official edit and a concurrent participant submission target the same score, the director's latest authorized decision wins and becomes the new official revision.
- The participant submission is preserved as an immutable review record in the score's audit/revision history. It is never dropped.
- The losing participant submission does NOT notify the participant and does NOT auto-create a review request.
- The losing submission does NOT appear in the sync "conflicts requiring action" list and does NOT block sync. It is visible only in the score's audit/revision history and the score review surface; it remains inert until the director separately opens a review for that score.
- The prior official value, its actor, reason, and time are preserved in the audit trail alongside the new official revision.
- Derived scores and rankings are recomputed from the new official revision; they are never merged as source data.
- A score that is locked, or in a contest state that disallows modification, is rejected with an actionable explanation; a review request cannot modify a locked score.
- If a pending **review request**'s base revision is superseded by a director offline edit, the review request enters a "requires decision" state and must be explicitly approved, rejected, or superseded by the director — it is never auto-applied or auto-rejected. Approving applies the proposed change as the new official revision; rejecting keeps the current official (the offline edit) authoritative; the request and proposed values are retained in the audit trail in all cases.

## Decisions

- **Scope:** Director official edit vs. concurrent participant submission only. No helper-vs-helper and no stale-device handling in this ticket. (2026-09-21)
- **Resolution rule (per plan, reaffirmed):** The director's latest authorized decision is authoritative and takes precedence over the participant submission. The participant submission is never dropped — it is retained as a silent review record and is not automatically turned into a review request or participant notification.
- **Conflict UX:** The losing participant submission is a **silent review record with no forced action** — it does not block sync, does not appear in the conflicts-requiring-action list, and does not notify the participant. It is visible in the score's audit/revision history and score review surface, and remains inert until the director separately opens a review. (2026-09-21)
- **Superseded review request:** A pending review request whose base revision was changed by a director offline edit enters a "requires decision" state and requires the director to explicitly approve, reject, or supersede. No auto-apply, no auto-reject. Approve → proposed value becomes the new official revision; reject → the offline edit remains authoritative. The request and proposed values are retained in the audit trail in all cases. (2026-09-21)
- **Audit:** The prior official value, its actor, reason, and time are preserved in the audit trail alongside the new official revision.

## Status

- All open questions resolved. Ready for implementation.

## Sources

- `plan/architecture-requirements/offline-synchronization.md` (Authority and Conflict Resolution; Pull and Push Protocol; Scores and Recalculation; User Experience and Recovery)
- `plan/architecture-requirements/participant-score-entry.md` (Score submission, Synchronization and recovery)
- `plan/architecture-requirements/score-review-and-validity-state.md`
- `plan/business-requirements/score-review-requests.md`
- `plan/ui/participant-scoring/participant-scoring.md`
