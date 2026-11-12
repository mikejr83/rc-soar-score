import 'package:soar_score_core/soar_score_core.dart' as core;

import 'drift_repository.dart';
import '../sync/drift_sync_store.dart';
import '../sync/table_mapper.dart';


class PilotImportLinkRepository extends DriftRepository
    implements core.PilotImportLinkRepository {
  PilotImportLinkRepository(super.db, {super.stores});
  late final _links = store<core.PilotImportLink>('PilotImportLink');
  late final _profiles = store<core.ParticipantProfile>('ParticipantProfile');
  @override
  Future<List<core.PilotImportLink>> listForOwner(core.Id ownerAccountId) =>
      _links.whereId('owner_account_id', ownerAccountId);
  @override
  Future<Set<int>> pilotsUnderReview(core.Id ownerAccountId) async {
    final numbers = <int>{};
    void add(Object? payload) {
      final number = payload is Map ? payload['source_pilot_no'] : null;
      if (number is int) numbers.add(number);
    }

    // Both sides of every review that waits for the director.
    final scope = core.DirectorScopeKey(ownerAccountId);
    for (final conflict in await DriftSyncStore(
      db,
    ).conflictsNeedingAction(scope)) {
      if (conflict.entityType == 'PilotImportLink' &&
          conflict.reasonCode == core.SyncReasonCode.uniqueViolation.code) {
        add(conflict.acceptedPayload);
        add(conflict.competingPayload);
      }
    }
    return numbers;
  }

  @override
  Future<bool> managedElsewhere(core.Id ownerAccountId) async {
    // Mutation records may still carry the Local account's id from before the
    // sign-in claim, so they are matched by entity, not by owner.
    final mutations = await TableMapper(
      db,
      db.mutationRecords,
    ).where("entity_type = 'PilotImportLink'", const []);
    final written = {for (final row in mutations) row['entity_id']};
    final refused = mutations.any(
      (row) =>
          row['outcome'] == 'Rejected' &&
          row['reason_code'] == core.SyncReasonCode.notLinkManager.code,
    );
    if (refused) return true;
    // A link this installation never wrote came down from the service.
    return (await listForOwner(ownerAccountId))
        .any((link) => !written.contains(link.id.value));
  }

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
    Set<int>? reviewedPilotNumbers,
  }) => unitOfWork.run((context) async {
    if (reviewedOwner != null) {
      final held = await pilotsUnderReview(reviewedOwner);
      final touched = reviewedPilotNumbers == null
          ? held
          : held.where(reviewedPilotNumbers.contains).toSet();
      if (touched.isNotEmpty) {
        throw core.PilotImportLinkReviewError(touched);
      }
    }
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
