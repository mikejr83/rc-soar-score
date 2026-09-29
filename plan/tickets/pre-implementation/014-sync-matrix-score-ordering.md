# Ticket 014 — Offline Sync: Matrix Change + Score Entry Ordering

- **Category:** Offline Sync
- **Priority:** High
- **Status:** ready
- **Depends on:** ticket 003 (immutable revision model), ticket 021 (mid-contest re-draw), ticket 013 (score edit conflict), ticket 015 (partial-failure atomicity — referenced).
- **Decision:** Scores may only reference server-known groups except for a brand-new fully-offline unclaimed contest; push order is always matrix revision → scores that reference it (dependency order); a score arriving with an unknown revision/group is rejected with a machine-readable reason code and self-heals by re-pushing the revision; pending scores always stay linked to the revision they were entered under and a re-draw never reassigns existing scores (redrawing a scored round removes those scores locally first).

## Context

If a matrix revision is published (new round / re-draw) while offline score entries are queued, the sync order is unclear. The architecture doc already fixes two things: the service "applies non-conflicting mutations in **dependency order**", and existing scores "must remain linked to the matrix revision under which they were entered". Ticket 003 fixes the revision model (immutable snapshots; every round belongs to exactly one revision; a score references (revision, assignment chain)). What remains settled by this ticket is (a) when a client may *create* score entries against a revision the server does not know, and (b) the concrete push ordering and server-side handling for the one case where that can happen.

## Questions

1. **~~Can offline score entries reference flight groups that do not yet exist on the server (i.e., created by a locally-drawn round)?~~** — **Resolved: yes, but only for a brand-new, fully offline, unclaimed contest (Decision 1).**
2. **~~What is the sync order when both a matrix revision and score entries are pending — matrix first, then scores, or scores first, then matrix?~~** — **Resolved: revision always first, then the scores that reference it (Decision 2).**
3. **~~If a score entry references a group id that the server doesn't recognize, is it rejected, queued, or matched by a different key?~~** — **Resolved: rejected with a machine-readable reason code; client re-pushes the owning revision, then retries (Decision 3).**
4. **~~How does the client handle a matrix revision that changes group membership after scores were entered for the old grouping?~~** — **Resolved: pending scores keep referencing the revision under which they were entered; the new revision is pushed separately and never reassigns existing scores; redrawing a scored round removes those scores locally before the redraw (Decision 4).**

## Decisions Needed

- (All resolved — see Decisions.)

## Decisions

- **Q1 / offline-created groups (Decision 1):** A client may create score entries against a revision the server does not yet know **only for an initial, fully-offline, unclaimed contest** — one created and drawn entirely offline that has never had a server copy (anonymous / accountless until claimed). Once a contest has been claimed by an account or has any server revision, score entries may only target groups that already exist on the server; a locally-drawn revision must be synced (revision + groups + assignments) before scoring UI unlocks for it. Consequence: "orphan" score entries (referencing a not-yet-synced revision) can only ever exist in the fully-offline contest case. (2026-09-21)
- **Sync order (Decision 2, Q2):** In **both** scenarios the push order is **matrix revision first, then the score entries that reference it** — this is the "dependency order" the architecture doc requires. Concretely: the client emits the revision with its groups/assignments (top-down) and only after that revision is acknowledged does it emit score entries referencing it. In scenario S1 (fully-offline unclaimed contest) the client *may* enter scores against a local revision before it is synced, but sync still always emits revision→scores, so the server never receives a score pointing at an unknown group. In scenario S2 (claimed / online contest) the same ordering applies: revision → scores. The client's sync engine must therefore topologically order pending mutations so a revision always precedes the score entries that depend on it, and a score entry is never pushed in the same sync pass before its owning revision is acknowledged. (2026-09-21)
- **Server-side unknown group (Decision 3, Q3):** Decisions 1–2 prevent a score from arriving before its revision in normal flow. As a defensive server-side rule, if a score entry nonetheless references a matrix revision or group id the server does not recognize, the server **rejects** the mutation as an invalid operation with a machine-readable reason code (e.g. `unknown_matrix_revision` / `unknown_flight_group`). The mutation is acknowledged as rejected (not applied, not silently queued, not matched by an alternate key). The client retains the score in its outbox, and on retry **re-pushes the owning revision first**, then retries the score (self-healing). The server never stores a dangling score, and the rejection is auditable. (2026-09-21)
- **Re-draw vs. pending scores (Decision 4, Q4):** A mid-contest re-draw is itself a local mutation. Pending offline score entries **keep referencing the matrix revision under which they were entered** (Decision 2 / arch doc "existing scores must remain linked to the matrix revision under which they were entered"). The new revision (e.g. R2) is a separate local mutation and is pushed separately; it **never reassigns existing scores** to a new grouping.
  - **Future-only re-draw (the normal case, per ticket 021):** R2 changes only future rounds, so it is disjoint from the rounds the pending scores cover. There is no conflict — the scores sync against R1's grouping and R2 applies to the (still unscored) future rounds.
  - **Redrawing a scored round (rare, warned, per ticket 021):** before the re-draw takes effect locally, the client **removes the affected scores through the standard score-removal/audit path** (retained in audit history, not silently dropped). By the time sync resumes, those scores no longer exist locally, so there is nothing to reconcile against R2's new grouping. This is distinct from ticket 013's "losing submission is never dropped" rule: these scores were **pending (never submitted/acknowledged by the server)**, so removal is a local discard-with-audit, not a losing conflict record.
  - **Consequence:** the re-draw and the pending scores never collide at sync time — either they touch disjoint rounds (future-only) or the affected scores have already been removed locally before the redraw. (2026-09-21)

## Acceptance criteria

- **Score-entry gating (Decision 1):** In a claimed/online contest (or any contest that already has a server revision), the score-entry UI does not allow entering a score against a group that does not yet exist on the server. Scoring for a locally-drawn revision is locked until that revision (and its groups/assignments) has been synced and acknowledged. The only path by which a score can reference a not-yet-synced revision is a brand-new, fully-offline, unclaimed contest.
- **Push ordering (Decision 2):** The client's sync engine topologically orders pending mutations so that a matrix revision is always pushed (and acknowledged) before any score entry that references it. A score entry is never emitted in the same sync pass before its owning revision is acknowledged. This holds in both the fully-offline (S1) and claimed/online (S2) cases.
- **No dangling scores on the server (Decision 3):** The server never persists a score entry whose referenced matrix revision or group id is unknown. If such a mutation arrives, the server returns a rejection with a machine-readable reason code (`unknown_matrix_revision` / `unknown_flight_group`); the mutation is acknowledged as rejected, not applied and not silently queued, and an audit event is recorded.
- **Client self-healing on rejection (Decision 3):** On receiving such a rejection, the client keeps the score in its outbox and, before retrying the score, re-pushes the owning revision (re-determining dependency order), then retries the score.
- **Scores stay linked to their entered revision (Decision 4):** A pending/offline score entry always references the matrix revision under which it was entered. A subsequently created revision (e.g., from a re-draw) is pushed as a separate mutation and never reassigns an existing score to a new group.
- **Future-only re-draw (Decision 4):** When the re-draw affects only future (unscored) rounds, the pending scores are unaffected and sync against their original revision's grouping; the new revision applies only to the future rounds.
- **Redrawn scored round (Decision 4):** When a scored round is redrawn (the warned action per ticket 021), the affected local pending scores are removed through the standard score-removal/audit path before the re-draw takes effect (retained in audit history, not silently dropped), so they are never pushed and never conflict with the new grouping. This local discard is distinct from ticket 013's "losing submission is never dropped" rule because these scores were pending and never acknowledged by the server.
- **Traceability:** After any of the above flows, each accepted score can be traced to exactly one matrix revision (the one that drew its group's round) and to the assignment record that produced the scored flight, consistent with ticket 003.

## Sources

- `plan/architecture-requirements/matrix-draw.md`
- `plan/architecture-requirements/data/scores-and-results.md`
- `plan/architecture-requirements/offline-synchronization.md` (Pull and Push Protocol; Authority and Conflict Resolution)
- `plan/architecture-requirements/data/matrix-and-assignments.md`
- `plan/tickets/pre-implementation/003-data-matrix-revision-granularity.md`
- `plan/tickets/pre-implementation/021-state-mid-contest-redraw.md`
- `plan/tickets/pre-implementation/015-sync-partial-failure-atomicity.md`
