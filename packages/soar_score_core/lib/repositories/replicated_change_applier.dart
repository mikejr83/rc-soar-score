import 'replicated_change.dart';

/// Applies changes the service already accepted, separately from local writes.
///
/// Unlike a `UnitOfWork` write it keeps the service's revision and sequence
/// and creates no pending mutation. It must refuse an entity type that is
/// derived (`FlightResult`, `ParticipationStanding`, `TeamStanding`), because
/// derived values are recomputed and never synchronized. An entity type it
/// cannot store, derived or unknown, is refused with an
/// `UnsupportedEntityTypeError`, and no other error should look like one.
abstract interface class ReplicatedChangeApplier {
  /// Applies [change] atomically. Applying the same change again is a no-op.
  ///
  /// Completes with whether stored data changed: false when the store already
  /// held this revision or newer, or the entity to delete was not there.
  Future<bool> apply(ReplicatedChange change);
}
