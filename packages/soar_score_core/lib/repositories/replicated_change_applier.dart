import 'replicated_change.dart';

/// Applies changes the service already accepted, separately from local writes.
///
/// Unlike a `UnitOfWork` write it keeps the service's revision and sequence
/// and creates no pending mutation. It must refuse an entity type that is
/// derived (`FlightResult`, `ParticipationStanding`, `TeamStanding`), because
/// derived values are recomputed and never synchronized.
abstract interface class ReplicatedChangeApplier {
  /// Applies [change] atomically. Applying the same change again is a no-op.
  Future<void> apply(ReplicatedChange change);
}
