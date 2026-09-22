# Ticket 015 — Offline Sync: Partial Failure Mid-Sequence

- **Category:** Offline Sync
- **Priority:** Medium
- **Status:** ready
- **Depends on:** ticket 013 (score edit conflict), ticket 014 (matrix change + score entry ordering), ticket 010 (recalculation invalidation scope).
- **Decision:** Sync operates with per-mutation granularity (each mutation commits independently, receives its own ack or rejection, and independent valid mutations in a batch are committed without all-or-nothing rollback); client tracks outbox status per `clientMutationId` (acknowledged items are marked synced and cleared, failed/rejected items remain in outbox for retry/resolution); server recomputes provisional normalized group scores immediately in internal private state, but public site visibility and official standings remain decoupled until explicit publication or round completion.

## Context

When an offline client reconnects, it pushes a batch of mutations (e.g. dozens of score entries across multiple groups or rounds). If some mutations in the sequence fail (e.g. semantic validation errors, missing references, or transient issues), the exact atomicity boundary, client outbox resumption mechanics, and server-side calculation/visibility states must be unambiguous.

## Questions

1. **~~What is the atomicity boundary — is a group's worth of scores one unit, or is each score a unit?~~** — **Resolved: Per-mutation granularity (Decision 1).** The server processes each mutation in dependency order independently. Valid mutations commit and receive acknowledgements; failed mutations return actionable rejection codes without rolling back valid sibling mutations in the same batch.
2. **~~If score 5 of 10 in a group fails, does the client resume from score 5 or restart the whole group?~~** — **Resolved: Per-mutation outbox tracking (Decision 2).** Scores 1–4 are committed and acknowledged. Score 5 remains in the client's outbox in a rejected/error state. Scores 6–10 (if not dependent on 5) proceed and are acknowledged. The client only retries or prompts the director for unresolved items.
3. **~~Are partially-synced groups visible on the public site, or are they held until the full group is synced?~~** — **Resolved: Decoupled via explicit publication / round gate (Decision 3).** The server immediately recomputes provisional internal derived scores from accepted raw scores for private director views, but the public site snapshot and official standings projection do not change until explicitly published by the director or gated by round completion.
4. **~~How does the client track which scores have been synced (local offset, server ack per score)?~~** — **Resolved: By unique `clientMutationId` acknowledgements (Decision 2).** The server response returns discrete arrays of `{ mutationId, revision }` for successes and `{ mutationId, errorCode, message }` for rejections.

## Decisions Needed

- (All resolved — see Decisions.)

## Decisions

- **Per-Mutation Sync Granularity (Decision 1):** The push API accepts batches of mutations but processes and commits them with per-mutation atomicity. A single invalid or conflicting mutation does NOT cause an all-or-nothing rollback of the entire batch. Dependent mutations (e.g. a score referencing a failed matrix revision) are skipped with a dependency error, while independent mutations (e.g. valid scores in other groups/rounds) succeed and commit. (2026-09-21)
- **Client Outbox Tracking & Resumption (Decision 2):** The client tracks synchronization state on a per-mutation basis using `clientMutationId`. When the server returns the sync response:
  - Acknowledged mutations are marked as synced and purged/archived from the pending outbox.
  - Rejected mutations are flagged in the local database with their server error code/reason, surfacing in the offline UI's "Conflicts / Items Requiring Action" view.
  - The client cursor advances to the server's latest acknowledged change token. Subsequent sync attempts transmit only remaining pending mutations. (2026-09-21)
- **Provisional Derived Recalculations & Public Decoupling (Decision 3):** 
  - Upon committing each valid score, the server recalculates provisional group normalization and cumulative standings within the private contest domain model immediately (per ticket 010).
  - Background synchronization is strictly a private data-backup mechanism; it never automatically updates the public site projection or emits public notifications until an explicit publication snapshot is triggered or a round-completion publication rule is met. (2026-09-21)

## Acceptance Criteria

- [ ] The push sync API accepts mutation batches and evaluates each mutation independently in topological dependency order.
- [ ] Successful mutations commit to the database and generate a discrete acknowledgement payload containing `clientMutationId` and the resulting `entityRevision`.
- [ ] A validation error or conflict on one mutation does not abort or roll back previously committed or subsequent independent mutations in the same payload.
- [ ] If a mutation fails, the API returns a structured rejection object containing `clientMutationId`, `errorCode`, `reason`, and the current server `entityRevision`.
- [ ] The client's sync manager marks acknowledged mutations as completed and retains only unacknowledged or rejected mutations in the local outbox.
- [ ] The client offline frame displays the exact count of failed/rejected mutations and provides an inspection view detailing the mutation, error reason, and options to retry, edit, or discard.
- [ ] Server-side normalization calculations recompute provisional private standings immediately upon accepting raw score mutations.
- [ ] Ingesting raw scores via background sync does not modify the public contest projection (`apps/soar_score_public`) without an explicit publish action or configured round publication trigger.

## Sources

- `plan/architecture-requirements/offline-synchronization.md` (Pull and Push Protocol; Scores and Recalculation)
- `plan/architecture-requirements/data/synchronization-and-audit.md`
- `plan/tickets/pre-implementation/013-sync-score-edit-conflict.md`
- `plan/tickets/pre-implementation/014-sync-matrix-score-ordering.md`
- `plan/tickets/pre-implementation/010-scoring-recalculation-invalidation-scope.md`
