import 'sync_scope.dart';

/// An entity that travels through synchronization and carries a revision.
abstract interface class Synchronizable {
  /// The stream that carries this entity.
  ///
  /// Constant for most types; computed per instance for `Role`,
  /// `LandingTable` and `LandingResult`, which are director data when owned
  /// and system data otherwise.
  SyncScope get syncScope;

  /// Revision counter used for optimistic locking.
  ///
  /// Models never bump it; the unit of work does.
  int get revision;
}
