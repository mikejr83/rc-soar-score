import '../models/id.dart';
import '../models/sync/installation.dart';

/// Abstract persistence contract for [Installation]s, the registered copies
/// of the app that synchronize with the server.
///
/// Backend only: writes record no `MutationRecord`. Revoking an installation
/// and recording when it was last seen or synchronized are saves of a changed
/// [Installation].
abstract interface class InstallationRepository {
  Future<Installation?> findById(Id id);

  /// Every installation of [ownerAccountId], oldest first by id, revoked ones
  /// included.
  Future<List<Installation>> listForAccount(Id ownerAccountId);

  /// Stores [installation], replacing the stored one with the same id.
  Future<Installation> save(Installation installation);

  /// Removes the installation with [id]; returns whether one existed.
  Future<bool> remove(Id id);
}
