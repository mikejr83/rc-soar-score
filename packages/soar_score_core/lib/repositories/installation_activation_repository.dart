import '../models/id.dart';
import '../models/sync/installation_activation.dart';

/// Abstract persistence contract for [InstallationActivation]s, the periods
/// in which an installation is the active copy of a contest.
///
/// Backend only: writes record no `MutationRecord`. Ending an activation is a
/// save of [InstallationActivation.close].
abstract interface class InstallationActivationRepository {
  Future<InstallationActivation?> findById(Id id);

  /// The activation of [contestId] on [installationId] that has not ended, or
  /// `null`.
  Future<InstallationActivation?> findOpen({
    required Id contestId,
    required Id installationId,
  });

  /// Every activation of [contestId], oldest first by id.
  Future<List<InstallationActivation>> listForContest(Id contestId);

  /// Every activation on [installationId], oldest first by id.
  Future<List<InstallationActivation>> listForInstallation(Id installationId);

  /// Stores [activation], replacing the stored one with the same id.
  Future<InstallationActivation> save(InstallationActivation activation);

  /// Removes the activation with [id]; returns whether one existed.
  Future<bool> remove(Id id);
}
