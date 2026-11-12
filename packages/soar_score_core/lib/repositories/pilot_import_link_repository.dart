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
  Future<PilotImportLink> save(
    PilotImportLink link, {
    required MutationMetadata metadata,
  });
  Future<bool> delete(Id id, {required MutationMetadata metadata});
}
