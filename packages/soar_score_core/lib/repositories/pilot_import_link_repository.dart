import '../models/id.dart';
import '../models/imports/pilot_import_link.dart';
import '../models/participants/participant_profile.dart';
import 'mutation_metadata.dart';

abstract interface class PilotImportLinkRepository {
  Future<List<ParticipantProfile>> saveImport(
    List<ParticipantProfile> profiles,
    List<PilotImportLink> links, {
    required MutationMetadata metadata,
    Id? reviewedOwner,
    Map<Id, int>? reviewedLinks,
    Set<int>? reviewedPilotNumbers,
  });
  Future<List<PilotImportLink>> listForOwner(Id ownerAccountId);

  /// The source pilot numbers whose link is not settled: two installations
  /// linked the pilot differently and the director has not decided which link
  /// is right, or this installation's own link for it was set aside and its
  /// choice has not been sent yet. A link for such a pilot must not be reused
  /// by an import.
  Future<Set<int>> pilotsUnderReview(Id ownerAccountId);
  Future<PilotImportLink> save(
    PilotImportLink link, {
    required MutationMetadata metadata,
  });
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
