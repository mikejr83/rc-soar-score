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

  /// Applies [changes], the changes of one aggregate in sequence order, in
  /// one transaction: all of them are stored or, when one fails, none is.
  ///
  /// The service sends the changes of one operation (a promoted score with
  /// its placeholder, superseded reviews and the receipt of the intent that
  /// asked for it) as one aggregate, so no reader sees part of it. A change
  /// of the entity type `ScorePromotion` is the receipt of an intent in the
  /// outbox: it settles that intent as accepted, in the same transaction.
  /// A receipt for an intent this installation does not hold is skipped.
  ///
  /// Completes with whether stored data changed.
  Future<bool> applyAggregate(List<ReplicatedChange> changes);
}
