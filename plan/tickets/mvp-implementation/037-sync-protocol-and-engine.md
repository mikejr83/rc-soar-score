# Ticket 037 — Synchronization Protocol and Engine

> **This work is being implemented through GitHub issues.** The work items and acceptance criteria below are tracked in the epic [#83](https://github.com/mikejr83/rc-soar-score/issues/83) and its sub-issues [#84](https://github.com/mikejr83/rc-soar-score/issues/84) to [#92](https://github.com/mikejr83/rc-soar-score/issues/92), which replace the former single issue [#51](https://github.com/mikejr83/rc-soar-score/issues/51). The checkboxes in this file are not updated; follow progress in the issues. This document remains the specification they refer to.

- **Category:** Offline Sync / API
- **Priority:** High
- **Status:** Tracked in GitHub issues (this file is the specification only)

## Context

The native offline application stores all contest data locally (SQLite) and must keep it in step with the remote service (PostgreSQL). Web applications hold no contest data and call the API directly, so they never synchronize. The requirements are in [offline-synchronization.md](../../architecture-requirements/offline-synchronization.md) and [offline-usage.md](../../architecture-requirements/offline-usage.md); the entities are `Installation`, `InstallationActivation`, `MutationRecord`, `SyncCursor`, `ConflictRecord`, `Tombstone` and `AuditEvent` under [`plan/data-model/entities/`](../../data-model/entities/).

Tickets 035 and 036 define the models and storage, including the unit-of-work write path and the separate replicated-change path. This ticket builds the protocol and the two components that use them. Nothing here exists yet: `soar_score_api` has only a health DTO, the handlers have only placeholder routes, and the contest app's sync button (033) is a stub.

### Operating behaviour (decided)

1. **Initial sync.** When the native application is connected and authenticated, it synchronizes before anything else so local and remote state match.
2. **Write-through.** After that, a change is applied locally first and then sent to the remote API immediately. It is recorded as a `Pending` mutation and stays in the outbox until acknowledged.
3. **Disconnected.** If the remote API is unreachable, local work continues. Pending mutations are kept and sent on the next connection, which begins with a pull and then a push.
4. **Per-mutation outcome.** Each mutation commits or fails independently (pre-implementation decision 015). A rejection never rolls back valid siblings in the same batch.

### Decisions already recorded in the pre-implementation tickets

| Ticket                                                             | Decision this ticket must honour                                                                                                                                                                         |
| ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [013](../pre-implementation/013-sync-score-edit-conflict.md)       | A director's official edit beats a concurrent participant submission. The losing submission becomes a silent review record (`requires_action` false), never discarded, no notification. No field merge.  |
| [014](../pre-implementation/014-sync-matrix-score-ordering.md)     | Push order is matrix revision first, then the scores that reference it. A score with an unknown revision or group is rejected with a reason code and retried after its revision is pushed.               |
| [015](../pre-implementation/015-sync-partial-failure-atomicity.md) | Per-mutation granularity, per-`client_mutation_id` outbox tracking, and public visibility decoupled from sync.                                                                                           |
| [016](../pre-implementation/016-sync-config-contention.md)         | Optimistic concurrency on configuration revisions (stale base is `config_revision_conflict`), mandatory pull before push on reconnect, side-by-side reconciliation, one active installation per contest. |

## Scope

### 1. Protocol contract (`soar_score_api`)

Define the DTOs and typed errors with `json_annotation`, in the existing package conventions. All timestamps are UTC ISO 8601.

- **Installation registration:** register, list and revoke an installation for the authenticated account.
- **Administration activation:** activate an installation for a contest (`Initial`, `Replacement`, `Reclaim`), requiring an authenticated session of the owning account. Activation ends the previous open row in the same transaction.
- **Sync exchange**, one request per scope. The request carries the protocol and schema versions, the installation, the scope (a contest or the director's own data), the last acknowledged sequence, and the unsent mutations in dependency order. The response carries, for every submitted mutation, its outcome (`Accepted` with the new revision and sequence, `Rejected` or `Conflict` with a reason code and the current revision, or `Skipped` with the dependency that failed), then all accepted changes after the cursor in sequence order with a continuation token when paged.
- **System data stream:** pull-only, driven by `Installation.system_data_seq`.
- **Conflict resolution:** submit a director's choice (`KeptAccepted`, `TookCompeting`, `Merged`) as a mutation that resolves a `ConflictRecord`.
- **Full download and export/import:** a complete contest download for initializing a replacement installation, and an export that includes raw scores, revisions, audit history, conflicts, tombstones, pending mutations and publication references. Import preserves identifiers and never silently overwrites an existing contest.
- **Reason codes:** a single enumerated list shared by server and client, starting from those in [mutation_record.md](../../data-model/entities/mutation_record.md) (`stale_base`, `inactive_installation`, `unknown_matrix_revision`, `unknown_flight_group`, `entity_deleted`, `unique_violation`, `locked`, `unauthorized`) plus `config_revision_conflict`, `unsupported_protocol_version` and `schema_too_old`.

### 2. Server sync service (`soar_score_core`, `soar_score_api_handlers`, `soar_score_data`)

The acceptor is domain logic and belongs in core behind a repository contract. The handlers only route and translate. The data layer provides the transaction.

- Authenticate the director and verify access to the scope.
- Reject any mutation from an installation that has no open `InstallationActivation` for the contest (`inactive_installation`) or that is revoked.
- Apply each mutation once, keyed by `(contest_id, client_mutation_id)` or `(owner_account_id, client_mutation_id)`. A retry returns the original outcome.
- Evaluate against `base_revision`: current is accepted; stale is classified as an automatic merge (independent fields only), a director decision (`Conflict`, with a `ConflictRecord`), or an invalid operation (`Rejected`). Last-write-wins is never used for authoritative data.
- Assign the scope's strictly increasing `sequence` on acceptance and write the `AuditEvent`.
- Enforce the authority table: original score attempts are immutable, official scores follow the director's latest authorized decision, locked scores and states that disallow modification are rejected with an actionable reason, and derived values are never accepted as input.
- Honour tombstones: a change to a deleted entity is rejected with `entity_deleted`; tombstones are kept 90 days after acknowledgement.
- Create the server-originated mutations (placeholders created when a matrix revision is finalized, accepted participant scores) so that every accepted change reaches clients through the stream.
- Scope responses to the director's authorized data, and keep participant email and other private data subject to the privacy rules.
- Trigger recomputation of derived results from raw data after configuration, matrix and score changes. Do not sync derived rows.
- Return `unsupported_protocol_version` or `schema_too_old` before processing anything when the client is outside the supported range.

### 3. Client sync engine (native contest application)

**Package: `packages/soar_score_sync` (decided).** A new pure Dart package (no Flutter, no `dart:io` requirement beyond what `soar_score_api` already uses) that depends only on `soar_score_core` and `soar_score_api`. It does **not** depend on `soar_score_data`: the engine reaches local storage through a `SyncStore` contract defined in `soar_score_core` (outbox reads, outcome updates, cursor reads and writes, replicated-change apply, conflict and status queries), which `soar_score_data` implements over SQLite. Reasons: the engine stays testable with an in-memory fake store; drift, `sqlite3` and `drift_postgres` never enter its dependency closure; and the same contract is what the server-side acceptor uses against PostgreSQL. Only `apps/soar_score_contest` depends on the package, and only its native bootstrap imports it. `soar_score_server`, `soar_score_api_handlers`, `soar_score_ui` and the other apps must not depend on it. The shared protocol vocabulary (reason codes, outcomes, protocol version) is domain, so it lives in `soar_score_core`; `soar_score_api` holds the DTOs that carry it. The package has its own `AGENTS.md` recording these boundaries.

- **Initial sync and mandatory pull-first.** On connect, pull everything after the stored cursors before pushing. Pulled changes are applied through the replicated-change path and never create new pending mutations.
- **Outbox.** Read `Pending` mutations in dependency order (matrix revision before the scores that use it) and push per scope. Update each mutation's outcome from the response. Acknowledged items are cleared, rejected items stay with their reason, and `Skipped` items are retried after their dependency is accepted.
- **Write-through trigger.** After each local unit of work commits, schedule an immediate push of that scope when a connection and valid token exist. Coalesce bursts of changes into a small number of requests. A failed push must not roll back or block the local change.
- **Cursor safety.** Preserve unsent local mutations and audit history before applying remote changes, and advance the local cursor only after the returned changes are durably stored. Repeating a sync after a timeout must be safe.
- **Connectivity and auth.** Use the existing connectivity monitoring. Obtain tokens through the token provider the API client already accepts. Distinguish "offline", "token expired" and "server error" so the UI can report them.
- **Conflicts.** Store `ConflictRecord`s that need action and expose them for the side-by-side view (local value versus server value; keep local, accept server, or edit). Silent records (director versus participant) are stored but not surfaced as needing action.
- **Replacement installation.** Initialize from a full download or export, then activate while connected. A deactivated installation becomes read-only for administrative changes, can still export, and gets a clear message. The `Reclaim` flow requires a pull, reconciliation of conflicts, and an explicit "Reactivate as Primary and Sync" confirmation.
- **Status model.** Expose a stream of sync state: last successful sync per scope, pending mutation count, conflicts needing action, remote revision, active installation identity, and a persistent warning that changes after the last successful sync are not recoverable if the installation is lost.
- **Anonymous publishing contests.** An accountless local contest has no remote backup and does not synchronize until claimed. The engine must skip such contests and the UI must say why.
- **Web build.** Compiles out the engine entirely; the web application has no outbox.

### 4. Out of scope

- The sync button and status area UI beyond the interface the engine exposes (tickets 033 and 023 consume it).
- Publishing results and the anonymous publishing verification flow.
- Participant-side submission clients (the self-scoring app uses its own endpoints on the same contract).
- Multi-administrator contests, which are a documented future extension.
- Auth0 setup itself (ticket 010).

## Work Items

- [ ] Write the protocol specification as a short document under `plan/architecture-requirements/` (request and response shapes, the reason-code list, versioning rules, paging, idempotency, and the order in which a client must call things). Update `plan/INDEX.md`.
- [ ] Add the DTOs, typed errors and client methods to `soar_score_api` with tests against a mock HTTP client.
- [ ] Add the server acceptor contract and implementation, with the full authority and conflict matrix, in core and data, and the routes in `soar_score_api_handlers`. Tests run in process with no socket, as the handler package requires.
- [ ] Add installation registration, revocation and administration activation, including the single-open-activation rule.
- [ ] Define the `SyncStore` contract and the protocol vocabulary (reason codes, outcomes, versions) in `soar_score_core`, and implement `SyncStore` in `soar_score_data` (ticket 036 provides the unit of work and the replicated-change path it wraps).
- [ ] Scaffold `packages/soar_score_sync` (pubspec depending only on `soar_score_core` and `soar_score_api`, `analysis_options.yaml`, `AGENTS.md` with the boundaries above, README) and confirm Melos picks it up through the `packages/*` workspace glob. Wire it into `NativeBootstrap`. Leave `WebBootstrap` unchanged.
- [ ] Implement the outbox, pull-first sync, write-through scheduling, cursor handling and the status stream.
- [ ] Implement full download, export and import with identifier preservation.
- [ ] Implement protocol and schema version negotiation, including a forced-update response for old installations.
- [ ] Add end-to-end tests that run the real server handler over an in-memory or test PostgreSQL database against a real client engine over SQLite. Cover every scenario below.
- [ ] Replace the stub in ticket 033 with a call to the engine (or record that 033 is changed to consume the status stream).

### End-to-end scenarios that must pass

- Initial sync of a new installation, then write-through of a score edit.
- Offline edits followed by reconnect: pull first, then push, with no duplicates after a retried request.
- A timeout after the server committed: the retry returns the original outcome and creates nothing new.
- Batch with one rejected mutation: siblings commit and only the failed one stays in the outbox.
- Matrix revision and dependent scores pushed in order; a score with an unknown revision is rejected, then accepted after the revision is pushed.
- Director offline edit versus a participant submission for the same score: the director's value wins, the submission is kept as a silent record and visible in the score history.
- Stale configuration revision: `config_revision_conflict`, side-by-side resolution, then accepted.
- Two offline moves into the same lane: `Conflict` with `unique_violation`.
- Offline deletion: tombstone sent; an older change to the deleted entity is rejected with `entity_deleted`.
- Replacement installation activation: the old installation's later administrative mutation is rejected with `inactive_installation`; reclaim flow works after pull and reconciliation.
- Revoked installation and expired token handled without losing local data.
- Old schema version is told to update before syncing.
- Export of a contest including pending mutations, imported on a second machine without overwriting an existing contest.
- Locked score and locked-state rejections carry actionable reasons.

## Acceptance Criteria

- [ ] The protocol specification is written and linked from the plan index, and DTOs match it.
- [ ] Every requirement in the Synchronization Requirements list in `offline-synchronization.md` (1 to 9) is covered by an implementation and a test.
- [ ] A mutation is applied at most once, a retry is safe, and the client cursor advances only after durable storage.
- [ ] No authoritative data is resolved by last-write-wins. Every conflict is classified and preserved.
- [ ] The native application performs an initial sync, then writes through to the API, and keeps working with the remote API unreachable.
- [ ] Participant submissions are never dropped, including those that lose to an official value.
- [ ] The web build contains no sync engine and no local contest data.
- [ ] All end-to-end scenarios pass. PostgreSQL-backed runs are reported as unverified if no database was available.
- [ ] `dart analyze` and `dart test` pass in every package touched, and `flutter test` passes in the contest app.

## Dependencies

- [035-create-data-models.md](035-create-data-models.md) and [036-create-drift-schema.md](036-create-drift-schema.md) — models, unit of work, replicated-change path and storage.
- [006-scaffold-core-package.md](006-scaffold-core-package.md) and [014-setup-melos-workspace.md](014-setup-melos-workspace.md) — core package and the workspace that picks up the new package.
- [008-scaffold-api-package.md](008-scaffold-api-package.md), [017-sqlite-sync-schema.md](017-sqlite-sync-schema.md) (handlers extraction) and [018-embed-soar_score_api_handlers.md](018-embed-soar_score_api_handlers.md) — API client, shared routing and the embedded server.
- [010-setup-auth0-identity.md](010-setup-auth0-identity.md) — tokens for the remote API and JWT validation on the server.
- Pre-implementation decisions [013](../pre-implementation/013-sync-score-edit-conflict.md) to [016](../pre-implementation/016-sync-config-contention.md); if any is reopened, update the affected section here first.
- Consumed by [033-home-page-sync-action.md](033-home-page-sync-action.md), [023-application-status-area.md](023-application-status-area.md) and [022-continue-offline-desktop.md](022-continue-offline-desktop.md).

## Sources

- [Offline synchronization](../../architecture-requirements/offline-synchronization.md), [offline usage](../../architecture-requirements/offline-usage.md) and [participant score entry](../../architecture-requirements/participant-score-entry.md)
- [Synchronization and audit data requirements](../../architecture-requirements/data/synchronization-and-audit.md)
- [Data model sync scopes](../../data-model/README.md#sync-scope) and the sync entity documents
- Existing `apps/soar_score_contest/lib/platform/native_bootstrap.dart`, `lib/server/embedded_server.dart` and `lib/services/connectivity/`
