# Ticket 016 — Offline Sync: Concurrent Config Edits

- **Category:** Offline Sync
- **Priority:** Low
- **Status:** ready
- **Depends on:** ticket 004 (configuration override scope), ticket 010 (recalculation invalidation scope), ticket 013 (score edit conflict), ticket 015 (partial-failure atomicity).
- **Decision:** Contests have a strict 1:1 director account ownership and a single active administration installation; logging into a replacement device (Device B) displays an explicit warning before transferring offline authority; an inactive device (Device A) with offline edits is never stranded—upon reconnecting, it performs a mandatory Pull first, presents a side-by-side reconciliation interface for any conflicting configuration or score fields (no silent last-write-wins), and reclaims primary authority upon authenticated push of the reconciled mutations; configuration revisions use optimistic concurrency control (`base_config_revision`) and trigger automatic recalculation of derived scores on the server upon committing a new revision.

## Context

A contest has a single owning director account. When the director uses multiple devices (e.g., Device A at the field offline and Device B online), or when offline configuration changes collide with changes made on the server, the concurrency model, device activation warnings, and reconciliation flow must be explicit to prevent data loss or silent overwrites.

## Questions

1. **~~Is config editing optimistic-concurrency (version check) or last-write-wins?~~** — **Resolved: Optimistic Concurrency Control (OCC) with base revision check (Decision 1).** Mutations must supply `base_config_revision`. If stale, the server rejects the mutation with a `config_revision_conflict` error and requires local reconciliation; silent last-write-wins is prohibited.
2. **~~If a conflict is detected, is the user prompted to merge, or is one edit silently discarded?~~** — **Resolved: Side-by-side reconciliation UI (Decision 2).** Non-conflicting independent fields merge automatically. Incompatible conflicting fields are presented to the director side-by-side (`Local Value` vs. `Server Value`) with options to keep local, accept server, or edit manually. Edits are never silently discarded.
3. **~~Can two devices both create a new configuration revision, and how is the sequence number resolved?~~** — **Resolved: Single active installation + Reclaim & Push protocol (Decision 3).** Only the currently active installation (or a device executing the authenticated Reclaim flow) can commit a new revision on the server. The server assigns the next monotonic revision sequence upon accepting the reconciled mutation.
4. **~~Does a config edit conflict also affect the calculation revision sequence?~~** — **Resolved: Yes, automatic recalculation (Decision 4).** Applying a new configuration revision that impacts calculations invalidates prior derived results and increments the calculation revision sequence per ticket 010.

## Decisions Needed

- (All resolved — see Decisions.)

## Decisions

- **Single Active Installation & Device B Warning (Decision 1):**
  - A contest has one active administration installation. Multi-device access can only occur if the director logs in with the same owning account on a second device.
  - When opening a contest on Device B, if Device A is currently the active installation, Device B displays a confirmation warning: _"Contest is currently active on [Device A]. Activating this device will transfer offline authority here. If [Device A] has unsynchronized offline changes, it will need to reconcile before pushing again."_ (2026-09-21)
- **Device A Reconnect, Pull-First & Reclaim Protocol (Decision 2):**
  - If Device A has offline mutations and attempts to sync after Device B has been activated, the server returns an `inactive_installation` response with the server's current revision.
  - Device A does **not** discard or strand local mutations. Instead, Device A initiates a mandatory **Pull** of all remote changes committed by Device B.
  - Device A runs a local reconciliation step: non-conflicting changes are auto-merged, while direct field conflicts surface in a side-by-side comparison screen in the offline UI.
  - Once reconciled, the director confirms **"Reactivate as Primary & Sync"**. Device A submits an authenticated request that reclaims active installation authority on the server and applies the reconciled mutations in dependency order. (2026-09-21)
- **Optimistic Concurrency on Configuration (Decision 3):** Configuration mutations validate against `base_config_revision`. Revisions are strictly monotonic and assigned by the server upon successful mutation commit. (2026-09-21)
- **Derived Score Invalidation (Decision 4):** Any configuration revision change that affects scoring parameters (e.g. drop rules, target time, penalty scales) automatically triggers recalculation of derived scores on the server without modifying raw score components (per ticket 010). (2026-09-21)

## Acceptance Criteria

- [ ] Logging into a new device (Device B) with the director's account and opening an active contest displays an explicit warning before transferring active installation authority.
- [ ] Attempting to push mutations from a deactivated installation (Device A) returns an `inactive_installation` status code and does not delete local pending mutations.
- [ ] When an inactive installation reconnects, the offline UI initiates a Pull operation to download all remote changes since its last sync cursor.
- [ ] Independent non-conflicting changes between devices merge cleanly without user intervention.
- [ ] Conflicting configuration or score edits are presented to the director in a side-by-side reconciliation interface with clear choices (`Keep Local`, `Accept Server`, `Edit Manually`).
- [ ] After reconciliation, an authenticated Reclaim & Push request transfers active installation authority back to the submitting device and applies the reconciled mutations.
- [ ] Configuration mutations enforce optimistic concurrency using `base_config_revision`; stale direct pushes without reconciliation are rejected.
- [ ] Accepting a new configuration revision invalidates and recalculates derived scores on the server and advances the calculation revision metadata.

## Sources

- `plan/architecture-requirements/offline-synchronization.md` (Administration Installation; Authority and Conflict Resolution)
- `plan/architecture-requirements/data/synchronization-and-audit.md`
- `plan/architecture-requirements/data/disciplines-and-configuration.md`
- `plan/ui/contest-administration/offline-ui.md`
- `plan/tickets/pre-implementation/004-data-config-override-scope.md`
- `plan/tickets/pre-implementation/010-scoring-recalculation-invalidation-scope.md`
- `plan/tickets/pre-implementation/013-sync-score-edit-conflict.md`
- `plan/tickets/pre-implementation/015-sync-partial-failure-atomicity.md`
