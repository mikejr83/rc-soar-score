# soar_score_sync

The client sync engine for the Soar Score native contest application.

- `SyncEngine` syncs one scope at a time: it pulls first, pushes the outbox in dependency order, applies the service's answers through the `SyncStore` and `ReplicatedChangeApplier` contracts, and advances the cursor only after changes are stored.
- `SyncScheduler` turns "a local change was committed" into one coalesced push per scope.
- `SyncEngine.states` is a stream of `SyncState` for the status UI: last sync, pending count, conflicts, and why a sync failed (`offline`, `tokenExpired`, `serverError`, `updateRequired`, `inactiveInstallation`).

The protocol is specified in `plan/architecture-requirements/sync-protocol.md`. See `AGENTS.md` for the package boundaries.
