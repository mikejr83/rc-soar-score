/// Which synchronization stream carries an entity and who may write it.
///
/// Mirrors the Sync Scope table in `plan/data-model/README.md`.
enum SyncScope {
  /// Synchronized through the per-contest sequence.
  contest,

  /// A director's own data, synchronized through the per-director sequence.
  director,

  /// Reference data that only comes down from the service.
  system,

  /// Issued by the service (invitations).
  issued,

  /// Recomputed from other data; never a mutation.
  derived,

  /// Held only by the backend.
  backendOnly,
}
