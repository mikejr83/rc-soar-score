import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';

class PilotImportLinkRepository extends DriftRepository
    implements core.PilotImportLinkRepository {
  PilotImportLinkRepository(super.db, {super.stores});
  late final _links = store<core.PilotImportLink>('PilotImportLink');
  late final _profiles = store<core.ParticipantProfile>('ParticipantProfile');
  @override
  Future<List<core.PilotImportLink>> listForOwner(core.Id ownerAccountId) =>
      _links.whereId('owner_account_id', ownerAccountId);
  @override
  Future<core.PilotImportLink> save(
    core.PilotImportLink link, {
    required core.MutationMetadata metadata,
  }) => unitOfWork.run((context) async {
    final profile = await _profiles.find(link.participantProfileId);
    if (profile == null || profile.ownerAccountId != link.ownerAccountId)
      throw ArgumentError(
        'Pilot import link target must exist and belong to its owner',
      );
    return context.save(link, metadata: metadata);
  });
  @override
  Future<bool> delete(core.Id id, {required core.MutationMetadata metadata}) =>
      unitOfWork.run((context) async {
        final link = await _links.find(id);
        if (link == null) return false;
        await context.delete(link, metadata: metadata);
        return true;
      });
  Future<List<core.ParticipantProfile>> saveImport(
    List<core.ParticipantProfile> profiles,
    List<core.PilotImportLink> links, {
    required core.MutationMetadata metadata,
    core.Id? reviewedOwner,
    Map<core.Id, int>? reviewedLinks,
  }) => unitOfWork.run((context) async {
    if (reviewedOwner != null && reviewedLinks != null) {
      final current = await listForOwner(reviewedOwner);
      final revisions = {for (final link in current) link.id: link.revision};
      final changed = <core.Id>{
        for (final entry in revisions.entries)
          if (reviewedLinks[entry.key] != entry.value) entry.key,
        for (final id in reviewedLinks.keys)
          if (!revisions.containsKey(id)) id,
      };
      if (changed.isNotEmpty) {
        throw core.PilotImportReviewChangedError(changed.toList());
      }
    }
    final saved = <core.ParticipantProfile>[];
    for (final profile in profiles) {
      saved.add(
        await context.save(
          profile,
          metadata: metadata.forPart('profile-${profile.id.value}'),
        ),
      );
    }
    for (final link in links) {
      final target = await _profiles.find(link.participantProfileId);
      if (target == null || target.ownerAccountId != link.ownerAccountId)
        throw ArgumentError(
          'Pilot import link target must exist and belong to its owner',
        );
      await context.save(
        link,
        metadata: metadata.forPart('pilot-link-${link.id.value}'),
      );
    }
    return saved;
  });
}
