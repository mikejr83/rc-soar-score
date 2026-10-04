import 'sync_scope.dart';

/// An entity that belongs to a synchronization stream.
///
/// Append-only records such as `MutationRecord` have a scope but no revision,
/// so they implement this and not `Synchronizable`.
abstract interface class SyncScoped {
  /// The stream that carries this entity.
  ///
  /// Constant for most types; computed per instance where the owner decides:
  /// `contest_id` or `owner_account_id` on sync records, and
  /// `owner_account_id` on `Role`, `LandingTable` and `LandingResult`.
  SyncScope get syncScope;
}
